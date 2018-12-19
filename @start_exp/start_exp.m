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
        TestingPanel   matlab.ui.container.Panel
        Practice       matlab.ui.control.Button
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
        TimeWaitStartSecs = 5;
        TimeWaitEndSecs = 5;
        TimeTaskCueSecs = 4;
        TimeFixationSecs = 0.5;
        TimeStimuliSecs = 1;
        TimeBlankSecs = 1; % this blank screen is waiting for user's response
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
            app.Practice.BackgroundColor = 'white';
            app.Practice.Enable = 'off';
            app.TestingRun1.BackgroundColor = 'white';
            app.TestingRun1.Enable = 'off';
            app.TestingRun2.BackgroundColor = 'white';
            app.TestingRun2.Enable = 'off';
        end
        % process practice part
        function practice(app)
            [status, exception] = app.start_nback('prac');
            if status ~= 0
                app.Practice.BackgroundColor = 'red';
                rethrow(exception)
            else
                app.Practice.BackgroundColor = 'magenta';
                app.UserPracticedTimes = app.UserPracticedTimes + 1;
            end
        end
        % process testing part
        function testing(app, run)
            [status, exception] = app.start_nback('test', run);
            if status ~= 0
                app.(sprintf('TestingRun%d', run)).BackgroundColor = 'red';
                rethrow(exception)
            else
                app.(sprintf('UserIsTestedRun%d', run)) = true;
                app.(sprintf('TestingRun%d', run)).BackgroundColor = 'green';
            end
        end
        % initialize configurations
        sequence = init_config(app, part)
        % startup nback test
        [status, exception] = start_nback(app, part, run)
    end

    methods (Access = public)
        % register current user
        function registered = registerUser(app)
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
            existed_logs = dir(fullfile(app.LogFilePath, ...
                sprintf('%s-*', app.ExperimentName)));
            existed_identifiers = str2double(...
                regexp({existed_logs.name}, ...
                sprintf('(?<=%s-)\\d+', app.ExperimentName), ...
                'once', 'match'));
            if ismember(app.RegisterUserApp.Identifier, existed_identifiers)
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
            app.LogFileName = sprintf('%s-%d-%s', ...
                app.ExperimentName, app.RegisterUserApp.Identifier, ...
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
            app.Practice.Enable = 'on';
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
            app.Practice.Enable = 'off';
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

        % Button pushed function: Practice
        function PracticeButtonPushed(app, event)
            app.ModifyUser.Visible = 'off';
            app.practice();
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
            app.Practice.Enable = 'off';
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
            app.Practice.Enable = 'off';
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
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MainUI
            app.MainUI = uifigure;
            app.MainUI.AutoResizeChildren = 'off';
            app.MainUI.Color = [0.902 0.902 0.902];
            app.MainUI.Position = [100 100 600 400];
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
            app.UserPanel.Position = [171 185 260 179];

            % Create LabelUserId
            app.LabelUserId = uilabel(app.UserPanel);
            app.LabelUserId.BackgroundColor = [0.9412 0.9412 0.9412];
            app.LabelUserId.HorizontalAlignment = 'center';
            app.LabelUserId.FontName = 'SimHei';
            app.LabelUserId.FontWeight = 'bold';
            app.LabelUserId.Tooltip = {'输入被试的编号，必须是一个大于0的整数。'};
            app.LabelUserId.Position = [60 120 30 22];
            app.LabelUserId.Text = '编号';

            % Create ValueUserId
            app.ValueUserId = uilabel(app.UserPanel);
            app.ValueUserId.HorizontalAlignment = 'center';
            app.ValueUserId.FontName = 'SimSun';
            app.ValueUserId.Position = [139 120 89 22];
            app.ValueUserId.Text = '待录入';

            % Create LabelUserName
            app.LabelUserName = uilabel(app.UserPanel);
            app.LabelUserName.HorizontalAlignment = 'center';
            app.LabelUserName.FontName = 'SimHei';
            app.LabelUserName.FontWeight = 'bold';
            app.LabelUserName.Tooltip = {'输入被试的姓名，中英文都可以。'};
            app.LabelUserName.Position = [60 87 30 22];
            app.LabelUserName.Text = '姓名';

            % Create ValueUserName
            app.ValueUserName = uilabel(app.UserPanel);
            app.ValueUserName.HorizontalAlignment = 'center';
            app.ValueUserName.FontName = 'SimSun';
            app.ValueUserName.Position = [139 87 89 22];
            app.ValueUserName.Text = '待录入';

            % Create LabelUserSex
            app.LabelUserSex = uilabel(app.UserPanel);
            app.LabelUserSex.HorizontalAlignment = 'center';
            app.LabelUserSex.FontName = 'SimHei';
            app.LabelUserSex.FontWeight = 'bold';
            app.LabelUserSex.Tooltip = {'下拉选择被试的性别。'};
            app.LabelUserSex.Position = [60 55 30 22];
            app.LabelUserSex.Text = '性别';

            % Create ValueUserSex
            app.ValueUserSex = uilabel(app.UserPanel);
            app.ValueUserSex.HorizontalAlignment = 'center';
            app.ValueUserSex.FontName = 'SimSun';
            app.ValueUserSex.Position = [139 55 89 22];
            app.ValueUserSex.Text = '待录入';

            % Create NewUser
            app.NewUser = uibutton(app.UserPanel, 'push');
            app.NewUser.ButtonPushedFcn = createCallbackFcn(app, @NewUserButtonPushed, true);
            app.NewUser.BackgroundColor = [1 1 1];
            app.NewUser.FontName = 'SimHei';
            app.NewUser.FontWeight = 'bold';
            app.NewUser.Position = [149 14 69 22];
            app.NewUser.Text = '新用户';

            % Create ModifyUser
            app.ModifyUser = uibutton(app.UserPanel, 'push');
            app.ModifyUser.ButtonPushedFcn = createCallbackFcn(app, @ModifyUserButtonPushed, true);
            app.ModifyUser.BackgroundColor = [1 1 1];
            app.ModifyUser.FontName = 'SimHei';
            app.ModifyUser.FontWeight = 'bold';
            app.ModifyUser.Position = [42 14 69 22];
            app.ModifyUser.Text = '修改';

            % Create TestingPanel
            app.TestingPanel = uipanel(app.MainUI);
            app.TestingPanel.AutoResizeChildren = 'off';
            app.TestingPanel.ForegroundColor = [0 0.451 0.7412];
            app.TestingPanel.TitlePosition = 'centertop';
            app.TestingPanel.Title = '开始测验';
            app.TestingPanel.FontName = 'SimHei';
            app.TestingPanel.FontWeight = 'bold';
            app.TestingPanel.Position = [171 48 260 123];

            % Create Practice
            app.Practice = uibutton(app.TestingPanel, 'push');
            app.Practice.ButtonPushedFcn = createCallbackFcn(app, @PracticeButtonPushed, true);
            app.Practice.BackgroundColor = [1 1 1];
            app.Practice.FontName = 'SimHei';
            app.Practice.FontWeight = 'bold';
            app.Practice.Position = [95 71 69 22];
            app.Practice.Text = '练习';

            % Create TestingRun1
            app.TestingRun1 = uibutton(app.TestingPanel, 'push');
            app.TestingRun1.ButtonPushedFcn = createCallbackFcn(app, @TestingRun1ButtonPushed, true);
            app.TestingRun1.BackgroundColor = [0.8 0.8 0.8];
            app.TestingRun1.FontName = 'SimHei';
            app.TestingRun1.FontWeight = 'bold';
            app.TestingRun1.Position = [35 25 83 22];
            app.TestingRun1.Text = '正式-第一次';

            % Create TestingRun2
            app.TestingRun2 = uibutton(app.TestingPanel, 'push');
            app.TestingRun2.ButtonPushedFcn = createCallbackFcn(app, @TestingRun2ButtonPushed, true);
            app.TestingRun2.BackgroundColor = [0.8 0.8 0.8];
            app.TestingRun2.FontName = 'SimHei';
            app.TestingRun2.FontWeight = 'bold';
            app.TestingRun2.Position = [142 25 83 22];
            app.TestingRun2.Text = '正式-第二次';
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
