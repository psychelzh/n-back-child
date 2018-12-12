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
        Testing        matlab.ui.control.Button
    end

    
    properties (Access = private)
        RegisterUserApp % user register app
        UserRegisterTime % time of registering
        UserIsRegistered = false; % indicate user is registered
        UserIsPracticed = false; % practice completed
        UserIsTested = false; % test completed
        LogFilePath = 'logs'; % path of file to log result data
        LogFileName = []; % name of file to log result data
    end
    
    properties (Access = private, Constant)
        CreateTime = datetime; % create time of app
        ExperimentName = 'NBack'; % experiment time
    end
    
    methods (Access = private)
        % prepare for new user creation
        function initializeUserCreation(app)
            % deregister current user
            app.UserIsRegistered = false;
            app.UserIsPracticed = false;
            app.UserIsTested = false;
            app.ValueUserId.Text = '待录入';
            app.ValueUserName.Text = '待录入';
            app.ValueUserSex.Text = '待录入';
            app.LogFileName = [];
            % disable all the buttons
            app.ModifyUser.Visible = 'off';
            app.NewUser.Enable = 'off';
            app.Practice.BackgroundColor = 'white';
            app.Practice.Enable = 'off';
            app.Testing.BackgroundColor = 'white';
            app.Testing.Enable = 'off';
        end
        % process practice part
        function practice(app)
            [status, exception] = app.experiment('prac');
            app.UserIsPracticed = true;
            if status ~= 0
                app.Practice.BackgroundColor = 'red';
                rethrow(exception)
            else
                app.Practice.BackgroundColor = 'green';
            end
        end
        % process testing part
        function testing(app)
            [status, exception] = app.experiment('test');
            app.UserIsTested = true;
            if status ~= 0
                app.Testing.BackgroundColor = 'red';
                rethrow(exception)
            else
                app.Testing.BackgroundColor = 'green';
            end
        end
        % main experiment method
        [status, exception] = experiment(app, part)
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
                sprintf('%s-*.csv', app.ExperimentName)));
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
            % using 'csvy' format to serialize user info, learn more at https://csvy.org/
            % using file extension .csv
            app.LogFileName = sprintf('%s-%d-%s.csv', ...
                app.ExperimentName, app.RegisterUserApp.Identifier, ...
                datestr(app.UserRegisterTime, 'yyyymmdd_HHMMSS'));
            h_log_file = fopen(fullfile(app.LogFilePath, app.LogFileName), ...
                'w', 'n', 'UTF-8');
            fprintf(h_log_file, ...
                ['#---', ...
                '\n#file_encoding: UTF-8', ...
                '\n#experiment_name: %s', ...
                '\n#create_time: %s', ...
                '\n#register_time: %s', ...
                '\n#user: ', ...
                '\n#  id: %d', ...
                '\n#  name: %s', ...
                '\n#  sex: %s', ...
                '\n#---'], ...
                app.ExperimentName, ...
                app.CreateTime, ...
                app.UserRegisterTime, ...
                app.RegisterUserApp.Identifier, ...
                app.RegisterUserApp.Name, ...
                app.RegisterUserApp.Sex);
            fclose(h_log_file);
            % enable creating new user and modifying current user
            app.NewUser.Enable = 'on';
            app.ModifyUser.Visible = 'on';
            % enable testing now
            app.Practice.Enable = 'on';
            app.Testing.Enable = 'on';
        end
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % initialize buttons
            app.ModifyUser.Visible = 'off';
            app.NewUser.Enable = 'on';
            app.Practice.Enable = 'off';
            app.Testing.Enable = 'off';
            % initialize logging directory
            if ~exist(app.LogFilePath, 'dir')
                mkdir(app.LogFilePath)
            end
        end

        % Button pushed function: NewUser
        function NewUserButtonPushed(app, event)
            if app.UserIsRegistered && ~app.UserIsTested
                confirm_resp = questdlg( ...
                    '当前用户还未完成测验，是否强制新建用户？', ...
                    '新建用户确认', '是', '否', '否');
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

        % Button pushed function: Testing
        function TestingButtonPushed(app, event)
            if app.UserIsTested
                confirm_resp = questdlg( ...
                    '当前用户已完成测验，是否需要重新测验？', ...
                    '退出确认', '是', '否', '否');
                if strcmp(confirm_resp, '否')
                    return
                end
            end
            app.ModifyUser.Visible = 'off';
            app.Practice.Enable = 'off';
            app.testing();
        end

        % Close request function: MainUI
        function MainUICloseRequest(app, event)
            if app.UserIsRegistered && ~app.UserIsTested
                confirm_resp = questdlg( ...
                    '当前用户还未完成测验，是否确认退出？', ...
                    '退出确认', '是', '否', '否');
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
            app.UserPanel.Position = [171 161 260 179];

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
            app.ValueUserId.Position = [161 120 41 22];
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
            app.ValueUserName.Position = [161 87 41 22];
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
            app.ValueUserSex.Position = [161 55 41 22];
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
            app.TestingPanel.Position = [171 64 260 81];

            % Create Practice
            app.Practice = uibutton(app.TestingPanel, 'push');
            app.Practice.ButtonPushedFcn = createCallbackFcn(app, @PracticeButtonPushed, true);
            app.Practice.BackgroundColor = [1 1 1];
            app.Practice.FontName = 'SimHei';
            app.Practice.FontWeight = 'bold';
            app.Practice.Position = [42 21 69 22];
            app.Practice.Text = '练习';

            % Create Testing
            app.Testing = uibutton(app.TestingPanel, 'push');
            app.Testing.ButtonPushedFcn = createCallbackFcn(app, @TestingButtonPushed, true);
            app.Testing.BackgroundColor = [0.8 0.8 0.8];
            app.Testing.FontName = 'SimHei';
            app.Testing.FontWeight = 'bold';
            app.Testing.Position = [149 21 69 22];
            app.Testing.Text = '正式';
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