clear; clc; close all;
addpath('functions');
config = get_config();
%% ------------------------------------------------------------------------
% 1. DEFINE REINFORCEMENT LEARNING ENVIRONMENT
% -------------------------------------------------------------------------
% Observation State: [Beam_Idx_Norm, PSF]
% We normalize the Beam Index to 0-1 for better Neural Network performance
obs_info = rlNumericSpec([6 1], 'LowerLimit', [0; 0; -1; -1; -1; -1], 'UpperLimit', [1; 1; 1; 1; 1; 1]); 
obs_info.Name = 'RelativeState';
obs_info.Description = 'PSF, Rel_Bob(xz), Rel_Eve(xz), Beam';

% Action space (0=Stay, 1-8=Move, 9-10=Power)
act_info = rlFiniteSetSpec(0:10); 
act_info.Name = 'BeamControl';

% Create step and reset handles for enviroment
step_handle = @(action, logged_signals) step_function(action, logged_signals, config);
reset_handle = @() reset_function(config);

% Create the environment
env = rlFunctionEnv(obs_info, act_info, step_handle, reset_handle);


%% ------------------------------------------------------------------------
% 2. DEFINE DQN AGENT (Neural Network)
% -------------------------------------------------------------------------% --- A. Improved Network Architecture (Wider) ---
% Increasing to 256 neurons gives the agent memory capacity for the whole map
net = [
    featureInputLayer(6, 'Normalization', 'none', 'Name', 'state')
    fullyConnectedLayer(256, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(256, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(11, 'Name', 'output')
    ];
dnn = dlnetwork(net);

% --- B. Optimizer Options (Stabilization) ---
% Lower Learning Rate prevents "overwriting" knowledge too fast
% GradientThreshold stops "exploding gradients" when rewards spike
optimizerOpts = rlOptimizerOptions('LearnRate', 1e-4, ... 
                                   'GradientThreshold', 1);

critic = rlVectorQValueFunction(dnn, obs_info, act_info, ...
                                'ObservationInputNames', 'state', ...
                                'UseDevice', 'cpu'); % Use 'gpu' if you have one

% --- C. DQN Hyperparameters (Long-Term Memory) ---
agentOpts = rlDQNAgentOptions(...
    'SampleTime', 1, ...
    'TargetSmoothFactor', 1e-3, ...
    'DiscountFactor', 0.99, ...
    'MiniBatchSize', 128, ...      % Increase from 128
    'ExperienceBufferLength', 100000, ... % Larger buffer (Remember old episodes)
    'CriticOptimizerOptions', optimizerOpts);

% --- D. Exploration Strategy (Patience) ---
% Decay over 20,000 steps instead of 2,000.
agentOpts.EpsilonGreedyExploration.Epsilon = 1.0;
agentOpts.EpsilonGreedyExploration.EpsilonMin = 0.05;
agentOpts.EpsilonGreedyExploration.EpsilonDecay = 1e-4;

agent = rlDQNAgent(critic, agentOpts);


%% ------------------------------------------------------------------------
% 3. TRAINING LOOP
% -------------------------------------------------------------------------
trainOpts = rlTrainingOptions('MaxEpisodes', 1000, ...
                              'MaxStepsPerEpisode', 50, ... % Give agent 50 steps to find the user
                              'ScoreAveragingWindowLength', 20, ...
                              'Verbose', true, ...
                              'Plots', 'none', ...
                              'StopTrainingCriteria', 'AverageReward', ...
                              'StopTrainingValue', 750); % Stop if Secrecy Rate avg > 15 bits/s/Hz

fprintf('Starting Training...\n');
trainingStats = train(agent, env, trainOpts);
fprintf('Training Complete.\n');

% Save agent
save('trainedAgent.mat', 'agent', 'config');