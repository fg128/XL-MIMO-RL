clear; clc; close all;
addpath('functions');
config = get_config();
%% ------------------------------------------------------------------------
% 1. DEFINE REINFORCEMENT LEARNING ENVIRONMENT
% -------------------------------------------------------------------------
% Observation State: [Beam_Idx_Norm, PSF]
% We normalize the Beam Index to 0-1 for better Neural Network performance
obs_info = rlNumericSpec([2 1], 'LowerLimit', [0; 0], 'UpperLimit', [1; 1]); 
obs_info.Name = 'BeamState';
obs_info.Description = 'Normalized Beam Index and Power Split Factor';

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
% -------------------------------------------------------------------------
% Architecture: Input(2) -> FC(64) -> ReLU -> FC(64) -> ReLU -> Output(11)
net = [
    featureInputLayer(2, 'Normalization', 'none', 'Name', 'state')
    fullyConnectedLayer(64, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(64, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(11, 'Name', 'output') % 11 Q-values
    ];
dnn = dlnetwork(net);

% Create Critic
critic = rlVectorQValueFunction(dnn, obs_info, act_info);

% DQN Hyperparameters
agentOpts = rlDQNAgentOptions('SampleTime', 1, ...
                              'TargetSmoothFactor', 1e-3, ...
                              'DiscountFactor', 0.99, ... % Care about future rewards
                              'MiniBatchSize', 128, ...
                              'ExperienceBufferLength', 1e5); 

% Exploration Strategy (Epsilon Greedy)
% Start with 100% random actions, decay to 5% random actions
agentOpts.EpsilonGreedyExploration.Epsilon = 1.0;
agentOpts.EpsilonGreedyExploration.EpsilonDecay = 0.001;
agentOpts.EpsilonGreedyExploration.EpsilonMin = 0.05;

agent = rlDQNAgent(critic, agentOpts);


%% ------------------------------------------------------------------------
% 3. TRAINING LOOP
% -------------------------------------------------------------------------
trainOpts = rlTrainingOptions('MaxEpisodes', 1000, ...
                              'MaxStepsPerEpisode', 50, ... % Give agent 50 steps to find the user
                              'ScoreAveragingWindowLength', 20, ...
                              'Verbose', false, ...
                              'Plots', 'training-progress', ...
                              'StopTrainingCriteria', 'AverageReward', ...
                              'StopTrainingValue', 15); % Stop if Secrecy Rate avg > 15 bits/s/Hz

fprintf('Starting Training...\n');
trainingStats = train(agent, env, trainOpts);
fprintf('Training Complete.\n');