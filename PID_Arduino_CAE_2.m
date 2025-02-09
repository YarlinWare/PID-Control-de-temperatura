%% Ejemplo Monitoreo de señales en tiempo Real
function varargout = PID_Arduino_CAE(varargin)
    parar = false;
    fclose('all');
    global tiempo salida escalon control;
    fig(1) = figure('name', 'Monitor', 'menubar', 'none', 'position', [200 200 800 700], 'color', [0.2 0.4 0.6]);
    movegui(fig(1), 'center');
    
    % Configuración de ejes para los gráficos
    axe(1) = axes('parent', fig(1), 'units', 'pixels', 'position', [60 380 600 280], 'xlim', [0 40], 'ylim', [20 50], 'xgrid', 'on', 'ygrid', 'on');
    axe(2) = axes('parent', fig(1), 'units', 'pixels', 'position', [60 50 600 280], 'xlim', [0 40], 'ylim', [0 100], 'xgrid', 'on', 'ygrid', 'on');
    
    % Etiquetas de los ejes
    set(get(axe(1), 'XLabel'), 'String', 'Tiempo (Seg)');
    set(get(axe(1), 'YLabel'), 'String', 'Temperatura (°C)');
    set(get(axe(2), 'XLabel'), 'String', 'Tiempo (Seg)');
    set(get(axe(2), 'YLabel'), 'String', 'Control (%)');
    
    % Líneas para los gráficos
    lin(1) = line('parent', axe(1), 'xdata', [], 'ydata', [], 'Color', 'r', 'LineWidth', 2.5);
    lin(2) = line('parent', axe(1), 'xdata', [], 'ydata', [], 'Color', 'k', 'LineWidth', 2);
    lin(3) = line('parent', axe(2), 'xdata', [], 'ydata', [], 'Color', 'r', 'LineWidth', 2.5);
    
    % Elementos de la interfaz (textos y botones)
    Texto(1) = uicontrol('parent', fig(1), 'style', 'text', 'string', 'Puerto', 'position', [680 630 100 50], 'BackgroundColor', [0.2 0.4 0.6], 'fontsize', 18, 'ForegroundColor', 'w');
    Texto(2) = uicontrol('parent', fig(1), 'style', 'text', 'string', 'Setpoint', 'position', [680 280 100 50], 'BackgroundColor', [0.2 0.4 0.6], 'fontsize', 18, 'ForegroundColor', 'w');
    Texto(3) = uicontrol('parent', fig(1), 'style', 'text', 'string', 'Gráfico', 'position', [680 450 100 50], 'BackgroundColor', [0.2 0.4 0.6], 'fontsize', 18, 'ForegroundColor', 'w');
    
    bot(1) = uicontrol('parent', fig(1), 'style', 'pushbutton', 'string', 'Detener', 'position', [680 50 100 50], 'callback', @stop, 'fontsize', 11);
    bot(2) = uicontrol('parent', fig(1), 'style', 'pushbutton', 'string', 'Enviar', 'position', [680 200 100 50], 'callback', @enviar, 'fontsize', 11);
    bot(3) = uicontrol('parent', fig(1), 'style', 'pushbutton', 'string', 'Salvar', 'position', [680 400 100 50], 'callback', @salvar, 'fontsize', 11);
    
    txbx(1) = uicontrol('parent', fig(1), 'style', 'text', 'string', 'Temp', 'position', [680 100 100 50], 'fontsize', 11);
    txbx(2) = uicontrol('parent', fig(1), 'style', 'edit', 'string', '000', 'position', [680 250 100 50], 'fontsize', 11);
    
    % Selección del puerto serial
    ports = serialportlist("available");
    
    if isempty(ports)
        error('No se encontraron puertos seriales disponibles');
    end
    
    %puerta = ports(1);  % Asume el primer puerto disponible
    puerta = 'COM3';
    
    popup = uicontrol('parent', fig(1), 'Style', 'popup', 'String', ports, 'Position', [680 600 100 50], 'fontsize', 15, 'Callback', @puertas);
    
    %% Función para detener el proceso
    function varargout = stop(hObject, eventdata)
        parar = true;
        fclose(SerialP);
        delete(SerialP);
        clear SerialP;
    end
    
    %% Función para enviar datos
    function varargout = enviar(hObject, eventdata)
        deg1 = get(txbx(2), 'string');
        % Asegura que deg1 tenga 3 caracteres
        while strlength(deg1) < 3
            deg1 = ["0" + deg1];
        end
        
        deg = ["S" + deg1 + "$"];
        fwrite(SerialP, deg, 'uchar');
    end
    
    %% Función para seleccionar el puerto
    function varargout = puertas(hObject, eventdata)
        puerta = popup;
    end
    
    %% Función para salvar los datos
    function varargout = salvar(hObject, eventdata)
        % Renombra las variables
        rs = escalon;
        us = control;
        ys = salida;
        ts = tiempo;
        save('Datos.mat', 'ts', 'rs', 'ys', 'us');
        figure;
        subplot(2, 1, 1);
        plot(ts, rs, ts, ys, 'linewidth', 3), grid;
        title('Laboratorio de Temperatura');
        xlabel('Tiempo (s)');
        ylabel('Temperatura (°C)');
        
        subplot(2, 1, 2);
        plot(ts, us, 'linewidth', 3), grid;
        xlabel('Tiempo (s)');
        ylabel('Control (%)');
    end
    
    %% Inicialización de las variables para el gráfico
    tiempo = [0];
    salida = [25];
    escalon = [0];
    control = [0];
    deg1 = "0";
    
    dt = 1;
    limx = [0 40];
    limy = [20 50];
    set(axe(1), 'xlim', limx, 'ylim', limy);
    
    %% Configura el Puerto Serial
    try
        SerialP = serialport(puerta, 9600);
        disp(['Conectado al puerto: ', puerta]);
    catch ME
        error('No se pudo conectar al puerto serial. Error: %s', ME.message);
    end
    
    %% Grafico en tiempo real
    k = 5;
    nit = 10000;
    while ~parar
        % Lectura del Dato por Puerto Serial
        variable = (fread(SerialP, 30, 'uchar'));
        ini = find(variable == 73); % Busca el 'I' (Primer dato)
        ini = ini(1) + 1;
        fin = find(variable == 70); % Busca el 'F' (último dato)
        fin = fin(find(fin > ini)) - 1;
        fin = fin(1);
        tempC = char(variable(ini:fin))';
        temp = str2num(tempC);
        
        % Lectura de la señal de control
        ini = find(variable == 67); % Busca el 'C' (Primer dato)
        ini = ini(1) + 1;
        fin = find(variable == 82); % Busca el 'R' (último dato)
        fin = fin(find(fin > ini)) - 1;
        fin = fin(1);
        Con1 = char(variable(ini:fin))';
        cont = str2num(Con1);
        
        set(txbx(1), 'string', tempC);
        
        % Actualiza las variables para los gráficos
        tiempo = [tiempo tiempo(end) + dt];
        salida = [salida temp];
        control = [control cont];
        escalon = [escalon str2num(deg1)];
        set(lin(1), 'xdata', tiempo, 'ydata', salida);
        set(lin(2), 'xdata', tiempo, 'ydata', escalon);
        set(lin(3), 'xdata', tiempo, 'ydata', control);
        pause(dt); % Espera 1 seg para cada interacción
        
        if tiempo(end) >= limx
            limx = [0 limx(2) + 40];
            set(axe(1), 'xlim', limx);
            set(axe(2), 'xlim', limx);
        end
        
        if salida(end) >= limy
            limy = [20 limy(2) + 5];
            set(axe(1), 'ylim', limy);
        end
        
        k = k + 1;
        if k == nit
            parar = true;
        end
    end
    parar = false;
end
