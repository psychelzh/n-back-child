classdef register_user < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UserRegUI            matlab.ui.Figure
        UserPanel            matlab.ui.container.Panel
        LabelUserId          matlab.ui.control.Label
        InputUserId          matlab.ui.control.NumericEditField
        LabelUserName        matlab.ui.control.Label
        InputUserName        matlab.ui.control.EditField
        LabelUserSex         matlab.ui.control.Label
        InputUserSex         matlab.ui.control.DropDown
        ConfirmRegisterUser  matlab.ui.control.Button
    end

    
    properties (Access = public)
        Identifier = 1; % identifier of user
        Name = ''; % name of user
        Sex = '��' % sex of user
    end
    
    properties (Access = private)
        CallingApp % main app
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainAPP, user)
            app.CallingApp = mainAPP;
            if exist('user', 'var')
                app.Identifier = user.Identifier;
                app.InputUserId.Value = user.Identifier;
                app.Name = user.Name;
                app.InputUserName.Value = user.Name;
                app.Sex = user.Sex;
                app.InputUserSex.Value = user.Sex;
            end
        end

        % Value changed function: InputUserId
        function InputUserIdValueChanged(app, event)
            if mod(app.InputUserId.Value, 1) ~= 0
                uialert(app.UserRegUI, ...
                    '�û���ű���Ϊ���������������������������', '��Ч���')
                app.InputUserId.Value = round(app.InputUserId.Value);
            end
            app.Identifier = app.InputUserId.Value;
        end

        % Value changed function: InputUserName
        function InputUserNameValueChanged(app, event)
            app.Name = strtrim(app.InputUserName.Value);
        end

        % Value changed function: InputUserSex
        function InputUserSexValueChanged(app, event)
            app.Sex = app.InputUserSex.Value;
        end

        % Button pushed function: ConfirmRegisterUser
        function ConfirmRegisterUserButtonPushed(app, event)
            % register user
            registered = registerUser(app.CallingApp);
            % delete app if succeeded registering
            if registered
                delete(app)
            end
        end

        % Close request function: UserRegUI
        function UserRegUICloseRequest(app, event)
            confirm_resp = uiconfirm(app.UserRegUI, ...
                '�Ƿ�¼�뵱ǰ�û���', '�˳�ȷ��',  ...
                'Options', {'��', '��'}, 'DefaultOption', '��');
            if strcmp(confirm_resp, '��')
                registered = registerUser(app.CallingApp);
                if ~registered
                    return
                end
            end
            % enable creation of new user
            app.CallingApp.NewUser.Enable = 'on';
            delete(app)
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UserRegUI
            app.UserRegUI = uifigure;
            app.UserRegUI.AutoResizeChildren = 'off';
            app.UserRegUI.Position = [200 175 400 250];
            app.UserRegUI.Name = '¼���û�';
            app.UserRegUI.Resize = 'off';
            app.UserRegUI.CloseRequestFcn = createCallbackFcn(app, @UserRegUICloseRequest, true);

            % Create UserPanel
            app.UserPanel = uipanel(app.UserRegUI);
            app.UserPanel.AutoResizeChildren = 'off';
            app.UserPanel.ForegroundColor = [0 0.451 0.7412];
            app.UserPanel.TitlePosition = 'centertop';
            app.UserPanel.Title = '������Ϣ';
            app.UserPanel.FontName = 'SimHei';
            app.UserPanel.FontWeight = 'bold';
            app.UserPanel.Position = [79 41 260 179];

            % Create LabelUserId
            app.LabelUserId = uilabel(app.UserPanel);
            app.LabelUserId.BackgroundColor = [0.9412 0.9412 0.9412];
            app.LabelUserId.HorizontalAlignment = 'right';
            app.LabelUserId.FontName = 'SimHei';
            app.LabelUserId.FontWeight = 'bold';
            app.LabelUserId.Tooltip = {'���뱻�Եı�ţ�������һ������0��������'};
            app.LabelUserId.Position = [51 122 30 22];
            app.LabelUserId.Text = '���';

            % Create InputUserId
            app.InputUserId = uieditfield(app.UserPanel, 'numeric');
            app.InputUserId.Limits = [1 Inf];
            app.InputUserId.ValueDisplayFormat = '%.0f';
            app.InputUserId.ValueChangedFcn = createCallbackFcn(app, @InputUserIdValueChanged, true);
            app.InputUserId.Position = [96 122 108 22];
            app.InputUserId.Value = 1;

            % Create LabelUserName
            app.LabelUserName = uilabel(app.UserPanel);
            app.LabelUserName.HorizontalAlignment = 'right';
            app.LabelUserName.FontName = 'SimHei';
            app.LabelUserName.FontWeight = 'bold';
            app.LabelUserName.Tooltip = {'���뱻�Ե���������Ӣ�Ķ����ԡ�'};
            app.LabelUserName.Position = [51 89 30 22];
            app.LabelUserName.Text = '����';

            % Create InputUserName
            app.InputUserName = uieditfield(app.UserPanel, 'text');
            app.InputUserName.ValueChangedFcn = createCallbackFcn(app, @InputUserNameValueChanged, true);
            app.InputUserName.Position = [96 89 108 22];

            % Create LabelUserSex
            app.LabelUserSex = uilabel(app.UserPanel);
            app.LabelUserSex.HorizontalAlignment = 'right';
            app.LabelUserSex.FontName = 'SimHei';
            app.LabelUserSex.FontWeight = 'bold';
            app.LabelUserSex.Tooltip = {'����ѡ���Ե��Ա�'};
            app.LabelUserSex.Position = [51 57 30 22];
            app.LabelUserSex.Text = '�Ա�';

            % Create InputUserSex
            app.InputUserSex = uidropdown(app.UserPanel);
            app.InputUserSex.Items = {'��', 'Ů'};
            app.InputUserSex.ValueChangedFcn = createCallbackFcn(app, @InputUserSexValueChanged, true);
            app.InputUserSex.Position = [96 57 108 22];
            app.InputUserSex.Value = '��';

            % Create ConfirmRegisterUser
            app.ConfirmRegisterUser = uibutton(app.UserPanel, 'push');
            app.ConfirmRegisterUser.ButtonPushedFcn = createCallbackFcn(app, @ConfirmRegisterUserButtonPushed, true);
            app.ConfirmRegisterUser.BackgroundColor = [1 1 1];
            app.ConfirmRegisterUser.FontName = 'SimHei';
            app.ConfirmRegisterUser.FontWeight = 'bold';
            app.ConfirmRegisterUser.Tooltip = {'ȷ��¼�뵱ǰ���ԡ�'};
            app.ConfirmRegisterUser.Position = [115 18 69 22];
            app.ConfirmRegisterUser.Text = '¼��';
        end
    end

    methods (Access = public)

        % Construct app
        function app = register_user(varargin)

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UserRegUI)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UserRegUI)
        end
    end
end