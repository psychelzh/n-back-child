classdef start_exp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ONEBACKUIFigure  matlab.ui.Figure
        UserPanel        matlab.ui.container.Panel
        UserRegister     matlab.ui.control.Button
        UserModify       matlab.ui.control.Button
        UserSexLabel     matlab.ui.control.Label
        UserSex          matlab.ui.control.DropDown
        UserNameLabel    matlab.ui.control.Label
        UserName         matlab.ui.control.EditField
        UserIdLabel      matlab.ui.control.Label
        UserId           matlab.ui.control.NumericEditField
        TestingPanel     matlab.ui.container.Panel
        Practice         matlab.ui.control.Button
        Testing          matlab.ui.control.Button
    end

    
    properties (Access = private)
        user_id = 1; % identifier of user
        user_name = ''; % name of user
        user_sex = categorical("��", ["��", "Ů"]); % sex of user
        practiced = false;
        tested = false;
    end
    
    methods (Access = private)
        % process practice part
        function practice(app)
            app.mainOneback(app.user_id, 'prac')
        end
        % process testing part
        function testing(app)
            app.mainOneback(app.user_id, 'test')
        end
    end
    
    methods (Access = private, Static)
        mainOneback(user, part)
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
            app.practiced = true;
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
            app.tested = true;
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ONEBACKUIFigure
            app.ONEBACKUIFigure = uifigure;
            app.ONEBACKUIFigure.Color = [0.902 0.902 0.902];
            app.ONEBACKUIFigure.Position = [100 100 342 313];
            app.ONEBACKUIFigure.Name = 'ONE-BACK����';

            % Create UserPanel
            app.UserPanel = uipanel(app.ONEBACKUIFigure);
            app.UserPanel.ForegroundColor = [0 0.451 0.7412];
            app.UserPanel.TitlePosition = 'centertop';
            app.UserPanel.Title = '������Ϣ';
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
            app.UserRegister.Text = '¼��';

            % Create UserModify
            app.UserModify = uibutton(app.UserPanel, 'push');
            app.UserModify.ButtonPushedFcn = createCallbackFcn(app, @UserModifyButtonPushed, true);
            app.UserModify.BackgroundColor = [1 1 1];
            app.UserModify.FontName = 'SimHei';
            app.UserModify.FontWeight = 'bold';
            app.UserModify.Position = [41 20 69 22];
            app.UserModify.Text = '�޸�';

            % Create UserSexLabel
            app.UserSexLabel = uilabel(app.UserPanel);
            app.UserSexLabel.HorizontalAlignment = 'right';
            app.UserSexLabel.FontName = 'SimHei';
            app.UserSexLabel.FontWeight = 'bold';
            app.UserSexLabel.Tooltip = {'����ѡ���Ե��Ա�'};
            app.UserSexLabel.Position = [51 57 30 22];
            app.UserSexLabel.Text = '�Ա�';

            % Create UserSex
            app.UserSex = uidropdown(app.UserPanel);
            app.UserSex.Items = {'��', 'Ů'};
            app.UserSex.ValueChangedFcn = createCallbackFcn(app, @UserSexValueChanged, true);
            app.UserSex.Position = [96 57 108 22];
            app.UserSex.Value = '��';

            % Create UserNameLabel
            app.UserNameLabel = uilabel(app.UserPanel);
            app.UserNameLabel.HorizontalAlignment = 'right';
            app.UserNameLabel.FontName = 'SimHei';
            app.UserNameLabel.FontWeight = 'bold';
            app.UserNameLabel.Tooltip = {'���뱻�Ե���������Ӣ�Ķ����ԡ�'};
            app.UserNameLabel.Position = [51 89 30 22];
            app.UserNameLabel.Text = '����';

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
            app.UserIdLabel.Tooltip = {'���뱻�Եı�ţ�������һ������0��������'};
            app.UserIdLabel.Position = [51 122 30 22];
            app.UserIdLabel.Text = '���';

            % Create UserId
            app.UserId = uieditfield(app.UserPanel, 'numeric');
            app.UserId.Limits = [1 Inf];
            app.UserId.ValueDisplayFormat = '%.0f';
            app.UserId.ValueChangedFcn = createCallbackFcn(app, @UserIdValueChanged, true);
            app.UserId.Position = [96 122 108 22];
            app.UserId.Value = 1;

            % Create TestingPanel
            app.TestingPanel = uipanel(app.ONEBACKUIFigure);
            app.TestingPanel.ForegroundColor = [0 0.451 0.7412];
            app.TestingPanel.TitlePosition = 'centertop';
            app.TestingPanel.Title = '��ʼ����';
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
            app.Practice.Text = '��ϰ';

            % Create Testing
            app.Testing = uibutton(app.TestingPanel, 'push');
            app.Testing.ButtonPushedFcn = createCallbackFcn(app, @TestingButtonPushed, true);
            app.Testing.BackgroundColor = [1 1 1];
            app.Testing.FontName = 'SimHei';
            app.Testing.FontWeight = 'bold';
            app.Testing.Position = [147 17 69 22];
            app.Testing.Text = '��ʽ';
        end
    end

    methods (Access = public)

        % Construct app
        function app = start_exp

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ONEBACKUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ONEBACKUIFigure)
        end
    end
end