classdef start_exp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MainUI         matlab.ui.Figure
        UserPanel      matlab.ui.container.Panel
        UserRegister   matlab.ui.control.Button
        UserModify     matlab.ui.control.Button
        UserSexLabel   matlab.ui.control.Label
        UserSex        matlab.ui.control.DropDown
        UserNameLabel  matlab.ui.control.Label
        UserName       matlab.ui.control.EditField
        UserIdLabel    matlab.ui.control.Label
        UserId         matlab.ui.control.NumericEditField
        TestingPanel   matlab.ui.container.Panel
        Practice       matlab.ui.control.Button
        Testing        matlab.ui.control.Button
    end

    
    properties (Access = private)
        user_id = 1; % identifier of user
        user_name = ''; % name of user
        user_sex = categorical("男", ["男", "女"]); % sex of user
        user_practiced = false; % practice completed
        user_tested = false; % test completed
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
            app.Practice.Enable = 'off';
            app.Testing.Enable = 'off';
            app.UserModify.Visible = 'off';
        end

        % Value changed function: UserId
        function UserIdValueChanged(app, event)
            app.user_id = app.UserId.Value;
        end

        % Value changed function: UserSex
        function UserSexValueChanged(app, event)
            app.user_sex = app.UserSex.Value;
        end

        % Value changed function: UserName
        function UserNameValueChanged(app, event)
            app.user_name = app.UserName.Value;
        end

        % Button pushed function: UserRegister
        function UserRegisterButtonPushed(app, event)
            app.UserId.Enable = 'off';
            app.UserName.Enable = 'off';
            app.UserSex.Enable = 'off';
            app.UserRegister.Enable = 'off';
            app.UserModify.Visible = 'on';
            app.Practice.Enable = 'on';
            app.Testing.Enable = 'on';
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
            if ~app.user_tested
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
            app.UserId.ValueDisplayFormat = '%.0f';
            app.UserId.ValueChangedFcn = createCallbackFcn(app, @UserIdValueChanged, true);
            app.UserId.Position = [96 122 108 22];
            app.UserId.Value = 1;

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