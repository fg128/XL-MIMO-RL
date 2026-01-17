clear; clc; close all;
addpath('functions');
config = get_config();

% Define the file name to check for
model_file = '';
save_file = 'trainedAgent_3.mat';


%% ------------------------------------------------------------------------
% 1. DEFINE REINFORCEMENT LEARNING ENVIRONMENT (Must always be run)
% -------------------------------------------------------------------------
obs_info = rlNumericSpec([6 1], 'LowerLimit', [0; 0; -1; -1; -1; -1], 'UpperLimit', [1; 1; 1; 1; 1; 1]); 
obs_info.Name = 'RelativeState';
obs_info.Description = 'PSF, Rel_Bob(xz), Rel_Eve(xz), Beam';

act_info = rlFiniteSetSpec(0:10); 
act_info.Name = 'BeamControl';

step_handle = @(action, logged_signals) step_function(action, logged_signals, config);
reset_handle = @() reset_function(config);

env = rlFunctionEnv(obs_info, act_info, step_handle, reset_handle);


%% ------------------------------------------------------------------------
% 2. DEFINE OR LOAD DQN AGENT
% -------------------------------------------------------------------------
if isfile(model_file)
    fprintf('Loading existing agent from %s...\n', model_file);
    loadedData = load(model_file, 'agent');
    agent = loadedData.agent;
    
    % If you are resuming, you might not want to start at 100% random (Epsilon=1.0)
    % again. You can manually set the starting epsilon here:
    agent.AgentOptions.EpsilonGreedyExploration.Epsilon = 0.5; 
    
else
    fprintf('No existing model found. Creating new DQN Agent...\n');
    
    % --- A. Improved Network Architecture ---
    net = [
        featureInputLayer(6, 'Normalization', 'none', 'Name', 'state')
        fullyConnectedLayer(256, 'Name', 'fc1')
        reluLayer('Name', 'relu1')
        fullyConnectedLayer(256, 'Name', 'fc2')
        reluLayer('Name', 'relu2')
        fullyConnectedLayer(11, 'Name', 'output')
        ];
    dnn = dlnetwork(net);

    % --- B. Optimizer Options ---
    optimizerOpts = rlOptimizerOptions('LearnRate', 1e-4, ... 
                                       'GradientThreshold', 1);
    
    critic = rlVectorQValueFunction(dnn, obs_info, act_info, ...
                                    'ObservationInputNames', 'state', ...
                                    'UseDevice', 'cpu'); 

    % --- C. DQN Hyperparameters ---
    agentOpts = rlDQNAgentOptions(...
        'SampleTime', 1, ...
        'TargetSmoothFactor', 1e-3, ...
        'DiscountFactor', 0.99, ...
        'MiniBatchSize', 256, ...
        'ExperienceBufferLength', 100000, ... 
        'CriticOptimizerOptions', optimizerOpts);

    % --- D. Exploration Strategy ---
    agentOpts.EpsilonGreedyExploration.Epsilon = 1.0;
    agentOpts.EpsilonGreedyExploration.EpsilonMin = 0.05;
    agentOpts.EpsilonGreedyExploration.EpsilonDecay = 1e-4;

    % Create the new agent
    agent = rlDQNAgent(critic, agentOpts);
end


%% ------------------------------------------------------------------------
% 3. TRAINING LOOP
% -------------------------------------------------------------------------
% Note: You might want to increase MaxEpisodes if resuming
trainOpts = rlTrainingOptions('MaxEpisodes', 500, ...
                              'MaxStepsPerEpisode', 50, ...
                              'ScoreAveragingWindowLength', 20, ...
                              'Verbose', true, ...
                              'Plots', 'training-progress', ... % Changed to show plot
                              'StopTrainingCriteria', 'AverageReward', ...
                              'StopTrainingValue', 10^6); 

fprintf('Starting Training...\n');
trainingStats = train(agent, env, trainOpts);
fprintf('Training Complete.\n');

% Save agent (Overwrites the old file or creates a new one)
save(model_file, 'agent', 'config');