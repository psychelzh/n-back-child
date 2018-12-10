classdef start_exp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MainUI         matlab.ui.Figure
        UserPanel      matlab.ui.container.Panel
        UserIdLabel    matlab.ui.control.Label
        UserId         matlab.ui.control.NumericEditField
        UserNameLabel  matlab.ui.control.Label
        UserName       matlab.ui.control.EditField
        UserSexLabel   matlab.ui.control.Label
        UserSex        matlab.ui.control.DropDown
        UserRegister   matlab.ui.control.Button
        UserModify     matlab.ui.control.Button
        TestingPanel   matlab.ui.container.Panel
        Practice       matlab.ui.control.Button
        Testing        matlab.ui.control.Button
    end

    
    properties (Access = private)
        % user information
        user_id = 1; % identifier of user
        user_name = ''; % name of user
        user_sex = '男'; % sex of user
        % registration
        user_regtime; % register time
        user_registed = false; % indicator whether user is registered
        % experiment related
        exp_name = 'Oneback'; % experiment time
        user_practiced = false; % practice completed
        user_tested = false; % test completed
        log_file = []; % name of file to log result data
    end
    
    properties (Access = private, Constant)
        create_time = datetime; % create time of app
        log_dir = 'logs'; % directory to log data
    end
    
    methods (Access = private)
        % process practice part
        function practice(app)
            [status, exception] = app.mainOneback(app.user_id, 'prac');
            app.user_practiced = true;
            if status ~= 0
                app.Practice.BackgroundColor = 'red';
                rethrow(exception)
            end
        end
        % process testing part
        function testing(app)
            [status, exception] = app.mainOneback(app.user_id, 'test');
            app.user_tested = true;
            if status ~= 0
                app.Testing.BackgroundColor = 'red';
                rethrow(exception)
            end
        end
    end
    
    methods (Access = private, Static)
        [status, exception] = mainOneback(user, part)
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % initialize buttons
            app.Practice.Enable = 'off';
            app.Testing.Enable = 'off';
            app.UserModify.Visible = 'off';
            % initialize logging directory
            if ~exist(app.log_dir, 'dir')
                mkdir(app.log_dir)
            end
        end

        % Value changed function: UserId
        function UserIdValueChanged(app, event)
            tmp_id = app.UserId.Value;
            if round(tmp_id) ~= tmp_id
                msgbox('用户编号必须为整数，将向下取整。')
                app.UserId.Value = floor(tmp_id);
            end
            app.user_id = app.UserId.Value;
        end

        % Value changed function: UserSex
        function UserSexValueChanged(app, event)
            app.user_sex = app.UserSex.Value;
        end

        % Value changed function: UserName
        function UserNameValueChanged(app, event)
            app.user_name = strtrim(app.UserName.Value);
        end

        % Button pushed function: UserRegister
        function UserRegisterButtonPushed(app, event)
            if isempty(app.user_name)
                confirm_resp = questdlg( ...
                    '用户姓名好像未填写，是否返回填写？', ...
                    '录入确认', '是', '否', '是');
                if strcmp(confirm_resp, '是')
                    return
                end
            end
            app.UserId.Enable = 'off';
            app.UserName.Enable = 'off';
            app.UserSex.Enable = 'off';
            app.UserRegister.Enable = 'off';
            app.UserModify.Visible = 'on';
            app.Practice.Enable = 'on';
            app.Testing.Enable = 'on';
            app.user_regtime = datetime;
            % using 'csvy' format, learn more at https://csvy.org/
            % using file extension .csv 
            app.log_file = sprintf('%s-%d-%s.csv', ...
                app.exp_name, app.user_id, ...
                datestr(app.user_regtime, 'yyyymmddHHMMSS'));
            h_log_file = fopen(fullfile(app.log_dir, app.log_file), ...
                'w', 'n', 'UTF-8');
            fprintf(h_log_file, ...
                ['#---', ...
                '\n#file_encoding: UTF-8', ...
                '\n#exp_name: %s', ...
                '\n#create_time: %s', ...
                '\n#user: ', ...
                '\n#  regtime: %s', ...
                '\n#  id: %d', ...
                '\n#  name: %s', ...
                '\n#  sex: %s', ...
                '\n#---'], ...
                app.exp_name, ...
                app.create_time, ...
                app.user_regtime, ...
                app.user_id, ...
                app.user_name, ...
                app.user_sex);
            fclose(h_log_file);
            app.user_registed = true;
        end

        % Button pushed function: UserModify
        function UserModifyButtonPushed(app, event)
            app.UserId.Enable = 'on';
            app.UserName.Enable = 'on';
            app.UserSex.Enable = 'on';
            app.UserRegister.Enable = 'on';
            app.UserModify.Visible = 'off';
            app.Practice.Enable = 'off';
            app.Testing.Enable = 'off';
            delete(fullfile(app.log_dir, app.log_file));
            app.log_file = [];
            app.user_registed = false;
        end

        % Button pushed function: Practice
        function PracticeButtonPushed(app, event)
            app.UserId.Enable = 'off';
            app.UserName.Enable = 'off';
            app.UserSex.Enable = 'off';
            app.UserRegister.Enable = 'off';
            app.UserModify.Visible = 'off';
            app.practice();
        end

        % Button pushed function: Testing
        function TestingButtonPushed(app, event)
            app.UserId.Enable = 'off';
            app.UserName.Enable = 'off';
            app.UserSex.Enable = 'off';
            app.UserRegister.Enable = 'off';
            app.UserModify.Visible = 'off';
            app.Practice.Enable = 'off';
            app.testing();
        end

        % Close request function: MainUI
        function MainUICloseRequest(app, event)
            deletion_confirmed = true;
            if app.user_registed && ~app.user_tested
                confirm_resp = questdlg( ...
                    '当前用户还未完成测验，是否确认退出？', ...
                    '退出确认', '是', '否', '否');
                if strcmp(confirm_resp, '否')
                    deletion_confirmed = false;
                end
            end
            if deletion_confirmed
                delete(app)
            end
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MainUI
            app.MainUI = uifigure;
            app.MainUI.Color = [0.902 0.902 0.902];
            app.MainUI.Position = [100 100 342 313];
            app.MainUI.Name = 'ONE-BACK测验';
            app.MainUI.CloseRequestFcn = createCallbackFcn(app, @MainUICloseRequest, true);

            % Create UserPanel
            app.UserPanel = uipanel(app.MainUI);
            app.UserPanel.ForegroundColor = [0 0.451 0.7412];
            app.UserPanel.TitlePosition = 'centertop';
            app.UserPanel.Title = '被试信息';
            app.UserPanel.FontName = 'SimHei';
            app.UserPanel.FontWeight = 'bold';
            app.UserPanel.Position = [42 112 260 179];

            % Create UserIdLabel
            app.UserIdLabel = uilabel(app.UserPanel);
            app.UserIdLabel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.UserIdLabel.HorizontalAlignment = 'right';
            app.UserIdLabel.FontName = 'SimHei';
            app.UserIdLabel.FontWeight = 'bold';
            app.UserIdLabel.Tooltip = {'输入被试的编号，必须是一个大于0的整数。'};
            app.UserIdLabel.Position = [51 122 30 22];
            app.UserIdLabel.Text = '编号';

            % Create UserId
            app.UserId = uieditfield(app.UserPanel, 'numeric');
            app.UserId.Limits = [1 Inf];
            app.UserId.ValueChangedFcn = createCallbackFcn(app, @UserIdValueChanged, true);
            app.UserId.Position = [96 122 108 22];
            app.UserId.Value = 1;

            % Create UserNameLabel
            app.UserNameLabel = uilabel(app.UserPanel);
            app.UserNameLabel.HorizontalAlignment = 'right';
            app.UserNameLabel.FontName = 'SimHei';
            app.UserNameLabel.FontWeight = 'bold';
            app.UserNameLabel.Tooltip = {'输入被试的姓名，中英文都可以。'};
            app.UserNameLabel.Position = [51 89 30 22];
            app.UserNameLabel.Text = '姓名';

            % Create UserName
            app.UserName = uieditfield(app.UserPanel, 'text');
            app.UserName.ValueChangedFcn = createCallbackFcn(app, @UserNameValueChanged, true);
            app.UserName.Position = [96 89 108 22];

            % Create UserSexLabel
            app.UserSexLabel = uilabel(app.UserPanel);
            app.UserSexLabel.HorizontalAlignment = 'right';
            app.UserSexLabel.FontName = 'SimHei';
            app.UserSexLabel.FontWeight = 'bold';
            app.UserSexLabel.Tooltip = {'下拉选择被试的性别。'};
            app.UserSexLabel.Position = [51 57 30 22];
            app.UserSexLabel.Text = '性别';

            % Create UserSex
            app.UserSex = uidropdown(app.UserPanel);
            app.UserSex.Items = {'男', '女'};
            app.UserSex.ValueChangedFcn = createCallbackFcn(app, @UserSexValueChanged, true);
            app.UserSex.Position = [96 57 108 22];
            app.UserSex.Value = '男';

            % Create UserRegister
            app.UserRegister = uibutton(app.UserPanel, 'push');
            app.UserRegister.ButtonPushedFcn = createCallbackFcn(app, @UserRegisterButtonPushed, true);
            app.UserRegister.BackgroundColor = [1 1 1];
            app.UserRegister.FontName = 'SimHei';
            app.UserRegister.FontWeight = 'bold';
            app.UserRegister.Position = [148 20 69 22];
            app.UserRegister.Text = '录入';

            % Create UserModify
            app.UserModify = uibutton(app.UserPanel, 'push');
            app.UserModify.ButtonPushedFcn = createCallbackFcn(app, @UserModifyButtonPushed, true);
            app.UserModify.BackgroundColor = [1 1 1];
            app.UserModify.FontName = 'SimHei';
            app.UserModify.FontWeight = 'bold';
            app.UserModify.Position = [41 20 69 22];
            app.UserModify.Text = '修改';

            % Create TestingPanel
            app.TestingPanel = uipanel(app.MainUI);
            app.TestingPanel.ForegroundColor = [0 0.451 0.7412];
            app.TestingPanel.TitlePosition = 'centertop';
            app.TestingPanel.Title = '开始测验';
            app.TestingPanel.FontName = 'SimHei';
            app.TestingPanel.FontWeight = 'bold';
            app.TestingPanel.Position = [42 17 260 79];

            % Create Practice
            app.Practice = uibutton(app.TestingPanel, 'push');
            app.Practice.ButtonPushedFcn = createCallbackFcn(app, @PracticeButtonPushed, true);
            app.Practice.BackgroundColor = [0.502 0.502 0.502];
            app.Practice.FontName = 'SimHei';
            app.Practice.FontWeight = 'bold';
            app.Practice.Position = [40 17 69 22];
            app.Practice.Text = '练习';

            % Create Testing
            app.Testing = uibutton(app.TestingPanel, 'push');
            app.Testing.ButtonPushedFcn = createCallbackFcn(app, @TestingButtonPushed, true);
            app.Testing.BackgroundColor = [1 1 1];
            app.Testing.FontName = 'SimHei';
            app.Testing.FontWeight = 'bold';
            app.Testing.Position = [147 17 69 22];
            app.Testing.Text = '正式';
        end
    end

    methods (Access = public)

        % Construct app
        function app = start_exp(varargin)

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