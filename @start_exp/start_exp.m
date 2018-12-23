classdef start_exp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MainUI         matlab.ui.Figure
        UserPanel      matlab.ui.container.Panel
        LabelUserId    matlab.ui.control.Label
        ValueUserId    matlab.ui.control.Label
        LabelUserName  matlab.ui.control.Label
        ValueUserName  matlab.ui.control.Label
        LabelUserSex   matlab.ui.control.Label
        ValueUserSex   matlab.ui.control.Label
        NewUser        matlab.ui.control.Button
        ModifyUser     matlab.ui.control.Button
        PracticePanel  matlab.ui.container.Panel
        Practice0back  matlab.ui.control.Button
        PC0back        matlab.ui.control.Label
        Practice1back  matlab.ui.control.Button
        PC1back        matlab.ui.control.Label
        Practice2back  matlab.ui.control.Button
        PC2back        matlab.ui.control.Label
        PracticeAll    matlab.ui.control.Button
        PCAll          matlab.ui.control.Label
        TestingPanel   matlab.ui.container.Panel
        TestingRun1    matlab.ui.control.Button
        TestingRun2    matlab.ui.control.Button
    end

    
    properties (Access = private)
        RegisterUserApp % user register app
        UserRegisterTime % time of registering
        UserIsRegistered = false; % indicate user is registered
        UserPracticedTimes = 0; % how many times user is practiced
        UserIsTestedRun1 = false; % test run 1 is completed
        UserIsTestedRun2 = false; % test run 2 is completed
        LogFileName; % name of file to log result data
    end
    
    properties (Access = private, Constant)
        % experiment-related properties
        ExperimentName = 'NBack';
        StimuliSet = [1:4, 6:9];
        NumberTrialsPerBlock = 10;
        % timing information
        TimeWaitStartSecs = 6;
        TimeWaitEndSecs = 5;
        TimeTaskCueSecs = 4;
        TimeFixationSecs = 0.5;
        TimeStimuliSecs = 1;
        TimeBlankSecs = 1; % this blank screen is waiting for user's response
        TimeFeedbackSecs = 0.3;
        % external files
        ImageFilePath = 'image'; % path storing instruction images
        LogFilePath = 'logs'; % path of file to log result data
    end
    
    methods (Access = private)
        % prepare for new user creation
        function initializeUserCreation(app)
            % deregister current user
            app.UserIsRegistered = false;
            app.UserPracticedTimes = 0;
            app.UserIsTestedRun1 = false;
            app.UserIsTestedRun2 = false;
            app.ValueUserId.Text = '待录入';
            app.ValueUserName.Text = '待录入';
            app.ValueUserSex.Text = '待录入';
            app.LogFileName = [];
            % disable all the buttons
            app.ModifyUser.Visible = 'off';
            app.NewUser.Enable = 'off';
            app.PracticeAll.BackgroundColor = 'white';
            app.PracticeAll.Enable = 'off';
            app.TestingRun1.BackgroundColor = 'white';
            app.TestingRun1.Enable = 'off';
            app.TestingRun2.BackgroundColor = 'white';
            app.TestingRun2.Enable = 'off';
        end
        % process practice part
        function practice(app, task)
            [status, exception, recordings] = ...
                app.start_nback('Part', "prac", 'Task', task);
            calling_button = 'PracticeAll';
            accuracy_label = 'PCAll';
            if ~isempty(task)
                switch task
                    case "zero-back"
                        calling_button = 'Practice0back';
                        accuracy_label = 'PC0back';
                    case "one-back"
                        calling_button = 'Practice1back';
                        accuracy_label = 'PC1back';
                    case "two-back"
                        calling_button = 'Practice2back';
                        accuracy_label = 'PC2back';
                end
            end
            if status ~= 0
                app.(calling_button).BackgroundColor = 'red';
                rethrow(exception)
            else
                app.(calling_button).BackgroundColor = 'green';
                app.UserPracticedTimes = app.UserPracticedTimes + 1;
                % set accuracy label
                pc = sum(recordings.acc == 1) / sum(~isnan(recordings.acc));
                app.(accuracy_label).Text = sprintf('正确率：%.1f%%', pc * 100);
                app.(accuracy_label).Visible = 'on';
            end
        end
        % process testing part
        function testing(app, run)
            [status, exception] = ...
                app.start_nback('Part', "test", 'Run', run);
            if status ~= 0
                app.(sprintf('TestingRun%d', run)).BackgroundColor = 'red';
                rethrow(exception)
            else
                app.(sprintf('UserIsTestedRun%d', run)) = true;
                app.(sprintf('TestingRun%d', run)).BackgroundColor = 'green';
            end
        end
        % initialize configurations
        config = init_config(app, part)
        % startup nback test
        [status, exception, recordings] = start_nback(app, varargin)
    end
    
    methods (Access = public)
        % register current user
        function registered = registerUser(app)
            % specify log file name template
            logfile_store_pattern = sprintf('%s-Sub_%%03d-Time_%%s.mat', app.ExperimentName);
            logfile_search_pattern = sprintf('%s-Sub_%%03d-Time_*.mat', app.ExperimentName);
            % set default as successful register
            registered = true;
            % check user name input
            if isempty(app.RegisterUserApp.Name)
                confirm_resp = uiconfirm(app.RegisterUserApp.UserRegUI, ...
                    '用户姓名好像未填写，是否返回填写？', '录入确认',  ...
                    'Options', {'是', '否'}, 'DefaultOption', '是');
                if strcmp(confirm_resp, '是')
                    registered = false;
                    return
                end
            end
            % check user identifier duplication
            search_result = dir(fullfile(app.LogFilePath, ...
                sprintf(logfile_search_pattern, app.RegisterUserApp.Identifier)));
            if ~isempty(search_result)
                confirm_resp = uiconfirm(app.RegisterUserApp.UserRegUI, ...
                    '用户编号重复，是否返回修改？', '录入确认',  ...
                    'Options', {'是', '否'}, 'DefaultOption', '是', ...
                    'Icon', 'warning');
                if strcmp(confirm_resp, '是')
                    registered = false;
                    return
                end
            end
            % store register timestamp and status
            app.UserRegisterTime = datetime;
            app.UserIsRegistered = true;
            % display user information on the main app
            app.ValueUserId.Text = num2str(app.RegisterUserApp.Identifier);
            app.ValueUserName.Text = app.RegisterUserApp.Name;
            app.ValueUserSex.Text = app.RegisterUserApp.Sex;
            % return to using matlab .mat file to store results
            app.LogFileName = sprintf(logfile_store_pattern, ...
                app.RegisterUserApp.Identifier, ...
                datestr(app.UserRegisterTime, 'yyyymmdd_HHMMSS'));
            % create user structure to store
            user.id = app.RegisterUserApp.Identifier;
            user.name = app.RegisterUserApp.Name;
            user.sex = app.RegisterUserApp.Sex;
            user.create_time = app.UserRegisterTime;
            save(fullfile(app.LogFilePath, app.LogFileName), 'user')
            % enable creating new user and modifying current user
            app.NewUser.Enable = 'on';
            app.ModifyUser.Visible = 'on';
            % enable testing now
            app.Practice0back.Enable = 'on';
            app.Practice1back.Enable = 'on';
            app.Practice2back.Enable = 'on';
            app.PracticeAll.Enable = 'on';
            app.TestingRun1.Enable = 'on';
            app.TestingRun2.Enable = 'on';
        end
    end

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % initialize buttons
            app.ModifyUser.Visible = 'off';
            app.NewUser.Enable = 'on';
            app.Practice0back.Enable = 'off';
            app.PC0back.Visible = 'off';
            app.Practice1back.Enable = 'off';
            app.PC1back.Visible = 'off';
            app.Practice2back.Enable = 'off';
            app.PC2back.Visible = 'off';
            app.PracticeAll.Enable = 'off';
            app.PCAll.Visible = 'off';
            app.TestingRun1.Enable = 'off';
            app.TestingRun2.Enable = 'off';
            % create log file path if not existed
            if ~exist(app.LogFilePath, 'dir')
                mkdir(app.LogFilePath)
            end
        end

        % Button pushed function: NewUser
        function NewUserButtonPushed(app, event)
            if app.UserIsRegistered && ~(app.UserIsTestedRun1 && app.UserIsTestedRun2)
                confirm_resp = uiconfirm(app.MainUI, ...
                    '当前用户还未完成测验，是否强制新建用户？', '新建用户确认',  ...
                    'Options', {'是', '否'}, 'DefaultOption', '否');
                if strcmp(confirm_resp, '否')
                    return
                end
            end
            app.initializeUserCreation();
            app.RegisterUserApp = register_user(app);
        end

        % Button pushed function: ModifyUser
        function ModifyUserButtonPushed(app, event)
            delete(fullfile(app.LogFilePath, app.LogFileName));
            user.Identifier = str2double(app.ValueUserId.Text);
            user.Name = app.ValueUserName.Text;
            user.Sex = app.ValueUserSex.Text;
            app.initializeUserCreation();
            app.RegisterUserApp = register_user(app, user);
        end

        % Button pushed function: PracticeAll
        function PracticeAllButtonPushed(app, event)
            app.ModifyUser.Visible = 'off';
            app.practice("all");
        end

        % Button pushed function: TestingRun1
        function TestingRun1ButtonPushed(app, event)
            if app.UserIsTestedRun1
                confirm_resp = uiconfirm(app.MainUI, ...
                    '当前用户已完成第一次测验，是否需要重新开始？', '重测确认',  ...
                    'Options', {'是', '否'}, 'DefaultOption', '否');
                if strcmp(confirm_resp, '否')
                    return
                end
            end
            app.ModifyUser.Visible = 'off';
            app.PracticeAll.Enable = 'off';
            app.testing(1)
        end

        % Button pushed function: TestingRun2
        function TestingRun2ButtonPushed(app, event)
            if app.UserIsTestedRun2
                confirm_resp = uiconfirm(app.MainUI, ...
                    '当前用户已完成第二次测验，是否需要重新开始？', '重测确认',  ...
                    'Options', {'是', '否'}, 'DefaultOption', '否');
                if strcmp(confirm_resp, '否')
                    return
                end
            end
            app.ModifyUser.Visible = 'off';
            app.PracticeAll.Enable = 'off';
            app.testing(2)
        end

        % Close request function: MainUI
        function MainUICloseRequest(app, event)
            if app.UserIsRegistered && ~(app.UserIsTestedRun1 && app.UserIsTestedRun2)
                confirm_resp = uiconfirm(app.MainUI, ...
                    '当前用户还未完成测验，是否确认退出？', '退出确认',  ...
                    'Options', {'是', '否'}, 'DefaultOption', '否');
                if strcmp(confirm_resp, '否')
                    return
                end
            end
            delete(app.RegisterUserApp)
            delete(app)
        end

        % Button pushed function: Practice0back
        function Practice0backButtonPushed(app, event)
            app.ModifyUser.Visible = 'off';
            app.practice("zero-back")
        end

        % Button pushed function: Practice1back
        function Practice1backButtonPushed(app, event)
            app.ModifyUser.Visible = 'off';
            app.practice("one-back")
        end

        % Button pushed function: Practice2back
        function Practice2backButtonPushed(app, event)
            app.ModifyUser.Visible = 'off';
            app.practice("two-back")
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MainUI
            app.MainUI = uifigure;
            app.MainUI.AutoResizeChildren = 'off';
            app.MainUI.Color = [0.902 0.902 0.902];
            app.MainUI.Position = [100 100 600 561];
            app.MainUI.Name = '测验向导';
            app.MainUI.Resize = 'off';
            app.MainUI.CloseRequestFcn = createCallbackFcn(app, @MainUICloseRequest, true);

            % Create UserPanel
            app.UserPanel = uipanel(app.MainUI);
            app.UserPanel.AutoResizeChildren = 'off';
            app.UserPanel.ForegroundColor = [0 0.451 0.7412];
            app.UserPanel.TitlePosition = 'centertop';
            app.UserPanel.Title = '当前被试';
            app.UserPanel.FontName = 'SimHei';
            app.UserPanel.FontWeight = 'bold';
            app.UserPanel.Position = [171 342 260 180];

            % Create LabelUserId
            app.LabelUserId = uilabel(app.UserPanel);
            app.LabelUserId.BackgroundColor = [0.9412 0.9412 0.9412];
            app.LabelUserId.HorizontalAlignment = 'center';
            app.LabelUserId.FontName = 'SimHei';
            app.LabelUserId.FontWeight = 'bold';
            app.LabelUserId.Tooltip = {'输入被试的编号，必须是一个大于0的整数。'};
            app.LabelUserId.Position = [60 121 30 22];
            app.LabelUserId.Text = '编号';

            % Create ValueUserId
            app.ValueUserId = uilabel(app.UserPanel);
            app.ValueUserId.HorizontalAlignment = 'center';
            app.ValueUserId.FontName = 'SimSun';
            app.ValueUserId.Position = [139 121 89 22];
            app.ValueUserId.Text = '待录入';

            % Create LabelUserName
            app.LabelUserName = uilabel(app.UserPanel);
            app.LabelUserName.HorizontalAlignment = 'center';
            app.LabelUserName.FontName = 'SimHei';
            app.LabelUserName.FontWeight = 'bold';
            app.LabelUserName.Tooltip = {'输入被试的姓名，中英文都可以。'};
            app.LabelUserName.Position = [60 88 30 22];
            app.LabelUserName.Text = '姓名';

            % Create ValueUserName
            app.ValueUserName = uilabel(app.UserPanel);
            app.ValueUserName.HorizontalAlignment = 'center';
            app.ValueUserName.FontName = 'SimSun';
            app.ValueUserName.Position = [139 88 89 22];
            app.ValueUserName.Text = '待录入';

            % Create LabelUserSex
            app.LabelUserSex = uilabel(app.UserPanel);
            app.LabelUserSex.HorizontalAlignment = 'center';
            app.LabelUserSex.FontName = 'SimHei';
            app.LabelUserSex.FontWeight = 'bold';
            app.LabelUserSex.Tooltip = {'下拉选择被试的性别。'};
            app.LabelUserSex.Position = [60 56 30 22];
            app.LabelUserSex.Text = '性别';

            % Create ValueUserSex
            app.ValueUserSex = uilabel(app.UserPanel);
            app.ValueUserSex.HorizontalAlignment = 'center';
            app.ValueUserSex.FontName = 'SimSun';
            app.ValueUserSex.Position = [139 56 89 22];
            app.ValueUserSex.Text = '待录入';

            % Create NewUser
            app.NewUser = uibutton(app.UserPanel, 'push');
            app.NewUser.ButtonPushedFcn = createCallbackFcn(app, @NewUserButtonPushed, true);
            app.NewUser.BackgroundColor = [1 1 1];
            app.NewUser.FontName = 'SimHei';
            app.NewUser.FontWeight = 'bold';
            app.NewUser.Position = [149 15 69 22];
            app.NewUser.Text = '新用户';

            % Create ModifyUser
            app.ModifyUser = uibutton(app.UserPanel, 'push');
            app.ModifyUser.ButtonPushedFcn = createCallbackFcn(app, @ModifyUserButtonPushed, true);
            app.ModifyUser.BackgroundColor = [1 1 1];
            app.ModifyUser.FontName = 'SimHei';
            app.ModifyUser.FontWeight = 'bold';
            app.ModifyUser.Position = [42 15 69 22];
            app.ModifyUser.Text = '修改';

            % Create PracticePanel
            app.PracticePanel = uipanel(app.MainUI);
            app.PracticePanel.AutoResizeChildren = 'off';
            app.PracticePanel.ForegroundColor = [0 0.451 0.7412];
            app.PracticePanel.TitlePosition = 'centertop';
            app.PracticePanel.Title = '练习部分';
            app.PracticePanel.FontName = 'SimHei';
            app.PracticePanel.FontWeight = 'bold';
            app.PracticePanel.Position = [121 142 360 180];

            % Create Practice0back
            app.Practice0back = uibutton(app.PracticePanel, 'push');
            app.Practice0back.ButtonPushedFcn = createCallbackFcn(app, @Practice0backButtonPushed, true);
            app.Practice0back.BackgroundColor = [1 1 1];
            app.Practice0back.FontName = 'SimHei';
            app.Practice0back.FontWeight = 'bold';
            app.Practice0back.Position = [34 115 69 22];
            app.Practice0back.Text = '0-back';

            % Create PC0back
            app.PC0back = uilabel(app.PracticePanel);
            app.PC0back.HorizontalAlignment = 'center';
            app.PC0back.FontName = 'SimHei';
            app.PC0back.Position = [26 88 80 22];
            app.PC0back.Text = '正确率';

            % Create Practice1back
            app.Practice1back = uibutton(app.PracticePanel, 'push');
            app.Practice1back.ButtonPushedFcn = createCallbackFcn(app, @Practice1backButtonPushed, true);
            app.Practice1back.BackgroundColor = [1 1 1];
            app.Practice1back.FontName = 'SimHei';
            app.Practice1back.FontWeight = 'bold';
            app.Practice1back.Position = [145 115 69 22];
            app.Practice1back.Text = '1-back';

            % Create PC1back
            app.PC1back = uilabel(app.PracticePanel);
            app.PC1back.HorizontalAlignment = 'center';
            app.PC1back.FontName = 'SimHei';
            app.PC1back.Position = [139 88 80 22];
            app.PC1back.Text = '正确率';

            % Create Practice2back
            app.Practice2back = uibutton(app.PracticePanel, 'push');
            app.Practice2back.ButtonPushedFcn = createCallbackFcn(app, @Practice2backButtonPushed, true);
            app.Practice2back.BackgroundColor = [1 1 1];
            app.Practice2back.FontName = 'SimHei';
            app.Practice2back.FontWeight = 'bold';
            app.Practice2back.Position = [256 115 69 22];
            app.Practice2back.Text = '2-back';

            % Create PC2back
            app.PC2back = uilabel(app.PracticePanel);
            app.PC2back.HorizontalAlignment = 'center';
            app.PC2back.FontName = 'SimHei';
            app.PC2back.Position = [252 88 80 22];
            app.PC2back.Text = '正确率';

            % Create PracticeAll
            app.PracticeAll = uibutton(app.PracticePanel, 'push');
            app.PracticeAll.ButtonPushedFcn = createCallbackFcn(app, @PracticeAllButtonPushed, true);
            app.PracticeAll.BackgroundColor = [1 1 1];
            app.PracticeAll.FontName = 'SimHei';
            app.PracticeAll.FontWeight = 'bold';
            app.PracticeAll.FontColor = [0 0 1];
            app.PracticeAll.Tooltip = {'将0-back，1-back和2-back综合在一起练习。'};
            app.PracticeAll.Position = [146 45 69 22];
            app.PracticeAll.Text = '综合';

            % Create PCAll
            app.PCAll = uilabel(app.PracticePanel);
            app.PCAll.HorizontalAlignment = 'center';
            app.PCAll.FontName = 'SimHei';
            app.PCAll.Position = [139 18 80 22];
            app.PCAll.Text = '正确率';

            % Create TestingPanel
            app.TestingPanel = uipanel(app.MainUI);
            app.TestingPanel.AutoResizeChildren = 'off';
            app.TestingPanel.ForegroundColor = [0 0.451 0.7412];
            app.TestingPanel.TitlePosition = 'centertop';
            app.TestingPanel.Title = '正式测试';
            app.TestingPanel.FontName = 'SimHei';
            app.TestingPanel.FontWeight = 'bold';
            app.TestingPanel.Position = [171 42 260 80];

            % Create TestingRun1
            app.TestingRun1 = uibutton(app.TestingPanel, 'push');
            app.TestingRun1.ButtonPushedFcn = createCallbackFcn(app, @TestingRun1ButtonPushed, true);
            app.TestingRun1.BackgroundColor = [1 1 1];
            app.TestingRun1.FontName = 'SimHei';
            app.TestingRun1.FontWeight = 'bold';
            app.TestingRun1.Position = [50 22 60 22];
            app.TestingRun1.Text = '第一次';

            % Create TestingRun2
            app.TestingRun2 = uibutton(app.TestingPanel, 'push');
            app.TestingRun2.ButtonPushedFcn = createCallbackFcn(app, @TestingRun2ButtonPushed, true);
            app.TestingRun2.BackgroundColor = [1 1 1];
            app.TestingRun2.FontName = 'SimHei';
            app.TestingRun2.FontWeight = 'bold';
            app.TestingRun2.Position = [160 22 60 22];
            app.TestingRun2.Text = '第二次';
        end
    end

    methods (Access = public)

        % Construct app
        function app = start_exp

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.MainUI)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MainUI)
        end
    end
end