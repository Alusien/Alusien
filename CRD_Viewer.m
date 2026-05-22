function CRD_Viewer()
% CRD_Viewer  Interactive GUI for ILRS CRD v2 files (full-rate .fr2 / normal-point .np2)
%
% Usage:
%   CRD_Viewer()          — opens the GUI; use the Load buttons to open files
%
% Supports:
%   • CRD v2.01 format (case-insensitive record IDs, "na" numeric fields)
%   • Full-rate (.fr2) and normal-point (.np2) files
%   • Optional second file for side-by-side station comparison
%
% Tabs: Overview | Range & Residuals | Calibration | Meteo | Pointing | Statistics
%
% Tested target: LAGEOS-2, stations MSLR (9991) and MATM (7941)

    % ------------------------------------------------------------------ %
    %  Build the main UI figure                                            %
    % ------------------------------------------------------------------ %
    fig = uifigure('Name','ILRS CRD v2 Viewer', ...
                   'Position',[50 50 1400 850], ...
                   'Color',[0.13 0.14 0.16], ...
                   'Resize','on');

    % App state
    app.fig   = fig;
    app.crd1  = [];   % parsed CRD struct for file 1
    app.crd2  = [];   % parsed CRD struct for file 2 (optional)
    app.file1 = '';
    app.file2 = '';

    % Store app in figure UserData
    fig.UserData = app;

    % ---- Top toolbar ---- %
    tb = uitoolbar(fig);   %#ok — keep reference only if needed

    % ---- Layout: left panel (controls) + right tab group ---- %
    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth = {260, '1x'};
    mainGrid.BackgroundColor = [0.13 0.14 0.16];

    % LEFT panel
    leftPanel = uipanel(mainGrid, ...
        'BackgroundColor',[0.17 0.18 0.20], ...
        'BorderType','none');
    leftPanel.Layout.Column = 1;

    % RIGHT tab group
    tabGroup = uitabgroup(mainGrid);
    tabGroup.Layout.Column = 2;

    % Store tabGroup in figure for callbacks
    fig.UserData.tabGroup = tabGroup;

    % ---- Left panel content ---- %
    build_left_panel(fig, leftPanel);

    % ---- Tabs ---- %
    tabs = build_tabs(tabGroup);
    fig.UserData.tabs = tabs;

    % ---- Initial placeholder message ---- %
    show_placeholder(tabs);

end % CRD_Viewer

% =========================================================================
%  LEFT PANEL
% =========================================================================
function build_left_panel(fig, panel)
    g = uigridlayout(panel, [14 1]);
    g.RowHeight   = {30, 30, 8, 30, 30, 8, 30, 8, 180, 8, '1x', 8, 30, 30};
    g.ColumnWidth = {'1x'};
    g.BackgroundColor = [0.17 0.18 0.20];
    g.Padding = [10 10 10 10];
    g.RowSpacing = 4;

    lbl_style = {'FontColor',[0.8 0.85 0.9],'FontSize',11,'FontWeight','bold', ...
                 'BackgroundColor',[0.17 0.18 0.20],'HorizontalAlignment','left'};

    % --- File 1 ---
    uilabel(g, lbl_style{:}, 'Text','File 1 (Primary)');
    btn1 = uibutton(g, 'Text','Load File 1 (.fr2 / .np2)', ...
        'BackgroundColor',[0.22 0.55 0.80], ...
        'FontColor','white','FontWeight','bold', ...
        'ButtonPushedFcn', @(~,~) cb_load_file(fig,1));
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]); % spacer

    % --- File 2 ---
    uilabel(g, lbl_style{:}, 'Text','File 2 (Comparison, optional)');
    btn2 = uibutton(g, 'Text','Load File 2 (.fr2 / .np2)', ...
        'BackgroundColor',[0.22 0.70 0.45], ...
        'FontColor','white','FontWeight','bold', ...
        'ButtonPushedFcn', @(~,~) cb_load_file(fig,2));
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]); % spacer

    % --- Refresh ---
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]); % spacer
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]); % spacer

    % --- Info box ---
    infoBox = uitextarea(g, ...
        'Value',{'No file loaded.','','Use the buttons above', 'to open CRD v2 files.'}, ...
        'Editable','off', ...
        'BackgroundColor',[0.12 0.13 0.15], ...
        'FontColor',[0.65 0.75 0.85], ...
        'FontSize',10);
    fig.UserData.infoBox = infoBox;

    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]); % spacer

    % Filler
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]);
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]); % spacer

    % About
    uilabel(g,'Text','ILRS CRD v2 Viewer', ...
        'FontColor',[0.4 0.5 0.6],'FontSize',9,'BackgroundColor',[0.17 0.18 0.20]);
    uilabel(g,'Text','Station QC Tool', ...
        'FontColor',[0.3 0.4 0.5],'FontSize',9,'BackgroundColor',[0.17 0.18 0.20]);

    %#ok suppress unused variable warnings for layout objects
end

% =========================================================================
%  TABS
% =========================================================================
function tabs = build_tabs(tabGroup)
    names = {'Overview','Range & Residuals','Calibration','Meteo','Pointing','Statistics'};
    tabs  = struct();
    fnames = {'overview','range','calib','meteo','pointing','stats'};
    for k = 1:numel(names)
        t = uitab(tabGroup,'Title',names{k});
        t.BackgroundColor = [0.13 0.14 0.16];
        tabs.(fnames{k}) = t;
    end
end

function show_placeholder(tabs)
    fnames = fieldnames(tabs);
    for k = 1:numel(fnames)
        t = tabs.(fnames{k});
        uilabel(t, 'Text','Load a CRD file to display data.', ...
            'FontColor',[0.5 0.6 0.7], 'FontSize',14, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','center', ...
            'Position',[0 0 1 1], ...
            'Units','normalized', ...
            'BackgroundColor',[0.13 0.14 0.16]);
    end
end

% =========================================================================
%  FILE LOAD CALLBACK
% =========================================================================
function cb_load_file(fig, slot)
    app = fig.UserData;
    [fname, fpath] = uigetfile({'*.fr2;*.np2','CRD v2 Files (*.fr2,*.np2)'; ...
                                '*.*','All Files (*.*)'},'Select CRD v2 File');
    if isequal(fname,0), return; end
    fullpath = fullfile(fpath, fname);

    % Parse
    try
        crd = parse_crd_v2(fullpath);
    catch ME
        uialert(fig, sprintf('Parse error:\n%s', ME.message), 'Error');
        return;
    end

    if slot == 1
        app.crd1  = crd;
        app.file1 = fullpath;
    else
        app.crd2  = crd;
        app.file2 = fullpath;
    end
    fig.UserData = app;

    % Update info box
    update_info_box(fig);

    % Refresh all tabs
    refresh_all_tabs(fig);
end

% =========================================================================
%  INFO BOX UPDATE
% =========================================================================
function update_info_box(fig)
    app = fig.UserData;
    lines = {};
    for slot = 1:2
        if slot == 1,  crd = app.crd1;  prefix = 'File 1';
        else,           crd = app.crd2;  prefix = 'File 2'; end
        if isempty(crd), continue; end
        lines{end+1} = sprintf('=== %s ===', prefix); %#ok
        if isfield(crd,'H2')
            lines{end+1} = sprintf('Station: %s (CDP %s)', crd.H2.station_name, crd.H2.cdp_pad_id); %#ok
        end
        if isfield(crd,'H3')
            lines{end+1} = sprintf('Target:  %s', crd.H3.target_name); %#ok
        end
        if isfield(crd,'H4')
            lines{end+1} = sprintf('Start:   %04d-%02d-%02d %02d:%02d:%02d', ...
                crd.H4.start_year, crd.H4.start_month, crd.H4.start_day, ...
                crd.H4.start_hour, crd.H4.start_min, crd.H4.start_sec); %#ok
            lines{end+1} = sprintf('End:     %04d-%02d-%02d %02d:%02d:%02d', ...
                crd.H4.end_year, crd.H4.end_month, crd.H4.end_day, ...
                crd.H4.end_hour, crd.H4.end_min, crd.H4.end_sec); %#ok
        end
        if isfield(crd,'rec10') && ~isempty(crd.rec10)
            lines{end+1} = sprintf('Records 10: %d', size(crd.rec10,1)); %#ok
        end
        if isfield(crd,'rec11') && ~isempty(crd.rec11)
            lines{end+1} = sprintf('Records 11: %d', size(crd.rec11,1)); %#ok
        end
        lines{end+1} = ''; %#ok
    end
    if isempty(lines)
        lines = {'No file loaded.'};
    end
    app.infoBox.Value = lines;
end

% =========================================================================
%  REFRESH ALL TABS
% =========================================================================
function refresh_all_tabs(fig)
    app = fig.UserData;
    tabs = app.tabs;

    % Clear all tabs
    fnames = fieldnames(tabs);
    for k = 1:numel(fnames)
        t = tabs.(fnames{k});
        delete(t.Children);
    end

    % Rebuild each tab
    fill_tab_overview(fig, tabs.overview);
    fill_tab_range(fig, tabs.range);
    fill_tab_calib(fig, tabs.calib);
    fill_tab_meteo(fig, tabs.meteo);
    fill_tab_pointing(fig, tabs.pointing);
    fill_tab_stats(fig, tabs.stats);
end

% =========================================================================
%  TAB: OVERVIEW
% =========================================================================
function fill_tab_overview(fig, tab)
    app = fig.UserData;
    if isempty(app.crd1) && isempty(app.crd2)
        uilabel(tab,'Text','No data loaded.','FontColor',[0.6 0.7 0.8],...
            'FontSize',13,'HorizontalAlignment','center',...
            'Units','normalized','Position',[0 0 1 1],...
            'BackgroundColor',[0.13 0.14 0.16]);
        return;
    end

    g = uigridlayout(tab, [1 2]);
    g.BackgroundColor = [0.13 0.14 0.16];
    g.ColumnWidth = {'1x','1x'};
    g.Padding = [10 10 10 10];

    for slot = 1:2
        if slot == 1, crd = app.crd1; else, crd = app.crd2; end
        col_panel = uipanel(g,'BackgroundColor',[0.15 0.16 0.18],'BorderType','none');
        col_panel.Layout.Column = slot;
        if isempty(crd)
            uilabel(col_panel,'Text','(no file)','FontColor',[0.4 0.5 0.6],...
                'FontSize',12,'HorizontalAlignment','center',...
                'Units','normalized','Position',[0 0 1 1],...
                'BackgroundColor',[0.15 0.16 0.18]);
            continue;
        end
        build_overview_panel(col_panel, crd, slot);
    end
end

function build_overview_panel(panel, crd, slot)
    colors = {[0.22 0.55 0.80],[0.22 0.70 0.45]};
    hdrColor = colors{slot};

    % Scrollable panel: use textarea with all info as text
    lines = crd_to_overview_lines(crd);

    g = uigridlayout(panel,[2 1]);
    g.RowHeight = {30,'1x'};
    g.BackgroundColor = [0.15 0.16 0.18];
    g.Padding = [6 6 6 6];

    title_str = sprintf('File %d — Station Overview', slot);
    uilabel(g,'Text',title_str,...
        'FontColor',hdrColor,'FontWeight','bold','FontSize',13,...
        'BackgroundColor',[0.15 0.16 0.18]);

    uitextarea(g,'Value',lines,'Editable','off',...
        'BackgroundColor',[0.10 0.11 0.13],...
        'FontColor',[0.82 0.88 0.95],...
        'FontSize',11,'FontName','Courier New');
end

function lines = crd_to_overview_lines(crd)
    lines = {};
    function addl(s), lines{end+1} = s; end
    function addkv(k,v), addl(sprintf('  %-28s %s', k, v)); end
    function addsep(title)
        addl('');
        addl(sprintf('─── %s ', title));
    end

    addsep('SESSION HEADER');
    if isfield(crd,'H1')
        addkv('Format:',   sprintf('CRD v%d  Released: %04d-%02d-%02d', ...
            crd.H1.crd_version, crd.H1.year, crd.H1.month, crd.H1.day));
    end
    if isfield(crd,'H2')
        addkv('Station:',  crd.H2.station_name);
        addkv('CDP Pad ID:',crd.H2.cdp_pad_id);
        addkv('CDP Sys ID:',num2str(crd.H2.cdp_sys_num));
        addkv('CDP Occ ID:',num2str(crd.H2.cdp_occ_num));
        addkv('Timescale:', num2str(crd.H2.timescale));
        addkv('Network:',   crd.H2.network);
    end
    if isfield(crd,'H3')
        addl('');
        addsep('TARGET');
        addkv('Name:',     crd.H3.target_name);
        addkv('ILRS ID:',  crd.H3.ilrs_id);
        addkv('SIC:',      crd.H3.sic);
        addkv('NORAD:',    crd.H3.norad);
        addkv('Spacecraft flag:', num2str(crd.H3.sc_flag));
    end
    if isfield(crd,'H4')
        addl('');
        addsep('PASS TIMES');
        addkv('Start:',sprintf('%04d-%02d-%02d  %02d:%02d:%02d UTC', ...
            crd.H4.start_year,crd.H4.start_month,crd.H4.start_day,...
            crd.H4.start_hour,crd.H4.start_min,crd.H4.start_sec));
        addkv('End:',  sprintf('%04d-%02d-%02d  %02d:%02d:%02d UTC', ...
            crd.H4.end_year,crd.H4.end_month,crd.H4.end_day,...
            crd.H4.end_hour,crd.H4.end_min,crd.H4.end_sec));
        addkv('Sys delay applied:',  num2str(crd.H4.sysdelay_applied));
        addkv('Tropo corr applied:',  num2str(crd.H4.tropo_applied));
        addkv('CoM corr applied:',    num2str(crd.H4.com_applied));
        addkv('Data release flag:',   num2str(crd.H4.data_release));
        addkv('Ranging mode:',        num2str(crd.H4.ranging_mode));
    end
    if isfield(crd,'H5')
        addl('');
        addsep('PREDICTION');
        addkv('Pred file name:',   crd.H5.pred_file_name);
        addkv('Pred point epoch:', num2str(crd.H5.pred_pnt_epoch));
    end

    % Configuration records
    if isfield(crd,'C0') && ~isempty(crd.C0)
        addl('');
        addsep('SYSTEM CONFIGURATION (C0)');
        for k = 1:numel(crd.C0)
            c = crd.C0(k);
            addkv(sprintf('Config[%d]:', c.detail_type), ...
                sprintf('%s  λ=%.2fnm', c.config_id, c.wavelength_nm));
        end
    end
    if isfield(crd,'C1') && ~isempty(crd.C1)
        addl('');
        addsep('LASER (C1)');
        for k = 1:numel(crd.C1)
            c = crd.C1(k);
            addkv(sprintf('[%s] Type:', c.laser_id), c.laser_type);
            addkv('  Wavelength (nm):',  num2str(c.wavelength_nm));
            addkv('  Rep rate (Hz):',    num2str(c.nom_fire_rate));
            addkv('  Pulse energy (mJ):',num2str(c.pulse_energy_mJ));
            addkv('  Pulse width (ps):', num2str(c.pulse_width_ps));
        end
    end
    if isfield(crd,'C2') && ~isempty(crd.C2)
        addl('');
        addsep('DETECTOR (C2)');
        for k = 1:numel(crd.C2)
            c = crd.C2(k);
            addkv(sprintf('[%s] Type:', c.detector_id), c.detector_type);
            addkv('  Wavelength (nm):',  num2str(c.wavelength_nm));
            addkv('  QE (%):', num2str(c.qe_pct));
        end
    end
    if isfield(crd,'C3') && ~isempty(crd.C3)
        addl('');
        addsep('TIMING (C3)');
        for k = 1:numel(crd.C3)
            c = crd.C3(k);
            addkv(sprintf('[%s] Freq (MHz):',c.timer_id),  num2str(c.freq_MHz));
            addkv('  Resolution (ps):',  num2str(c.time_resolution_ps));
        end
    end

    % Data counts
    addl('');
    addsep('DATA COUNTS');
    if isfield(crd,'rec10'), addkv('Full-rate records (10):', num2str(size(crd.rec10,1))); end
    if isfield(crd,'rec11'), addkv('Normal-point records (11):', num2str(size(crd.rec11,1))); end
    if isfield(crd,'rec12'), addkv('Mixed-rate records (12):', num2str(size(crd.rec12,1))); end
    if isfield(crd,'rec20'), addkv('Meteorology records (20):', num2str(size(crd.rec20,1))); end
    if isfield(crd,'rec30'), addkv('Pointing records (30):', num2str(size(crd.rec30,1))); end
    if isfield(crd,'rec40'), addkv('Cal pre-pass records (40):', num2str(size(crd.rec40,1))); end
    if isfield(crd,'rec41'), addkv('Cal post-pass records (41):', num2str(size(crd.rec41,1))); end
    if isfield(crd,'rec50'), addkv('Session stats records (50):', num2str(size(crd.rec50,1))); end
end

% =========================================================================
%  TAB: RANGE & RESIDUALS
% =========================================================================
function fill_tab_range(fig, tab)
    app = fig.UserData;
    have1 = ~isempty(app.crd1) && (isfield(app.crd1,'rec10')||isfield(app.crd1,'rec11'));
    have2 = ~isempty(app.crd2) && (isfield(app.crd2,'rec10')||isfield(app.crd2,'rec11'));
    if ~have1 && ~have2
        no_data_label(tab,'No range data available.');
        return;
    end

    % Outer grid: rows = [toolbar(30), plots(1x)]
    og = uigridlayout(tab,[2 1]);
    og.RowHeight = {30,'1x'};
    og.BackgroundColor = [0.13 0.14 0.16];
    og.Padding = [4 4 4 4];

    % Toolbar row: checkboxes / dropdown for controlling what to show
    tbRow = uigridlayout(og,[1 8]);
    tbRow.Layout.Row = 1;
    tbRow.BackgroundColor = [0.13 0.14 0.16];
    tbRow.ColumnWidth = {120,80,80,80,80,80,80,'1x'};

    uilabel(tbRow,'Text','Show:','FontColor',[0.8 0.85 0.9],'FontSize',11,...
        'BackgroundColor',[0.13 0.14 0.16]);
    cb_raw  = uicheckbox(tbRow,'Text','Raw TOF','Value',1,...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_sig  = uicheckbox(tbRow,'Text','Signal only','Value',0,...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_res  = uicheckbox(tbRow,'Text','Residuals','Value',1,...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_hist = uicheckbox(tbRow,'Text','Histogram','Value',1,...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_rate = uicheckbox(tbRow,'Text','Return rate','Value',1,...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    btnRefresh = uibutton(tbRow,'Text','Refresh','FontWeight','bold',...
        'BackgroundColor',[0.3 0.35 0.4],'FontColor','white');
    uilabel(tbRow,'Text','','BackgroundColor',[0.13 0.14 0.16]);

    % Plot area — will be built by draw function
    plotPanel = uipanel(og,'BackgroundColor',[0.13 0.14 0.16],'BorderType','none');
    plotPanel.Layout.Row = 2;

    % Draw initial plots
    draw_range_plots(fig, plotPanel, struct(...
        'raw',cb_raw,'signal',cb_sig,'resid',cb_res,'hist',cb_hist,'rate',cb_rate));

    % Wire refresh button
    btnRefresh.ButtonPushedFcn = @(~,~) draw_range_plots(fig, plotPanel, struct(...
        'raw',cb_raw,'signal',cb_sig,'resid',cb_res,'hist',cb_hist,'rate',cb_rate));
end

function draw_range_plots(fig, panel, opts)
    app = fig.UserData;
    delete(panel.Children);

    show_raw   = opts.raw.Value;
    sig_only   = opts.signal.Value;
    show_resid = opts.resid.Value;
    show_hist  = opts.hist.Value;
    show_rate  = opts.rate.Value;

    % Determine how many rows/cols for subplot grid
    nslots = sum([show_resid, show_hist, show_rate]);  % extra plots beyond main
    % Layout: top row = range scatter, bottom rows = residuals/hist/rate
    nrows = 1 + (nslots > 0);
    ncols = max(1, nslots);
    if nslots == 0, nrows = 1; ncols = 1; end

    % Use tiledlayout inside panel axes
    ax_container = uiaxes(panel,'Position',[0 0 1 1],'Units','normalized');
    ax_container.Visible = 'off';  % hide the placeholder axes

    % Build tiled layout
    tl = tiledlayout(panel, nrows, ncols, ...
        'TileSpacing','compact','Padding','compact', ...
        'BackgroundColor',[0.13 0.14 0.16]);

    colors_slot = {[0.22 0.65 0.95],[0.22 0.88 0.55]};
    colors_noise = {[0.7 0.3 0.3],[0.7 0.5 0.2]};

    % ── Main range plot (top row, spans all columns) ── %
    ax1 = nexttile(tl, 1, [1 max(1,ncols)]);
    style_axes(ax1);
    hold(ax1,'on');
    ax1.XLabel.String = 'Seconds of Day (s)';
    ax1.YLabel.String = 'Range (m)';
    ax1.Title.String  = 'One-Way Range vs Time';
    legend_entries = {};

    for slot = 1:2
        if slot == 1, crd = app.crd1; else, crd = app.crd2; end
        if isempty(crd), continue; end
        [sod, tof, filter] = get_range_data(crd);
        if isempty(sod), continue; end
        c_light = 299792458;   % m/s
        range_m = tof * c_light / 2;

        if show_raw && ~sig_only
            % Noise points
            idx_noise = filter ~= 2;
            if any(idx_noise)
                scatter(ax1, sod(idx_noise), range_m(idx_noise), 2, ...
                    colors_noise{slot},'filled','MarkerFaceAlpha',0.3,'DisplayName', ...
                    sprintf('Noise/Unknown (%s)',get_station_label(crd)));
                legend_entries{end+1} = sprintf('Noise S%d',slot); %#ok
            end
        end
        % Signal points
        idx_sig = filter == 2;
        if ~any(idx_sig), idx_sig = true(size(sod)); end  % fallback
        if sig_only, mask = idx_sig; else, mask = true(size(sod)); end
        scatter(ax1, sod(mask), range_m(mask), 3, colors_slot{slot},'filled', ...
            'MarkerFaceAlpha',0.6,'DisplayName', ...
            sprintf('%s (%d pts)',get_station_label(crd),sum(mask)));
    end
    legend(ax1,'show','Location','best','TextColor',[0.8 0.85 0.9],...
        'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax1,'off');

    % ── Secondary plots ── %
    if nslots == 0, return; end

    plot_idx = 0;
    for slot = 1:2
        if slot == 1, crd = app.crd1; else, crd = app.crd2; end
        if isempty(crd), continue; end
        [sod, tof, filter] = get_range_data(crd);
        if isempty(sod), continue; end
        c_light = 299792458;
        range_m = tof * c_light / 2;
        idx_sig = filter == 2;
        if ~any(idx_sig), idx_sig = true(size(sod)); end

        label = get_station_label(crd);

        if show_resid
            plot_idx = plot_idx + 1;
            ax = nexttile(tl, max(1,ncols) + plot_idx);
            style_axes(ax);
            resid_ps = compute_residuals_ps(sod(idx_sig), tof(idx_sig));
            scatter(ax, sod(idx_sig), resid_ps, 2, colors_slot{slot},'filled','MarkerFaceAlpha',0.5);
            hold(ax,'on');
            yline(ax,0,'--','Color',[0.7 0.7 0.7],'LineWidth',1);
            rms_val = sqrt(mean(resid_ps.^2));
            title(ax,sprintf('Residuals — %s  (RMS=%.1f ps)', label, rms_val),...
                'Color',[0.85 0.9 0.95],'FontSize',10);
            ax.XLabel.String = 'Seconds of Day (s)';
            ax.YLabel.String = 'Residual (ps)';
            hold(ax,'off');
        end
    end

    if show_hist
        plot_idx = plot_idx + 1;
        ax = nexttile(tl, max(1,ncols) + plot_idx);
        style_axes(ax); hold(ax,'on');
        for slot = 1:2
            if slot == 1, crd = app.crd1; else, crd = app.crd2; end
            if isempty(crd), continue; end
            [sod, tof, filter] = get_range_data(crd);
            if isempty(sod), continue; end
            idx_sig = filter == 2;
            if ~any(idx_sig), idx_sig = true(size(sod)); end
            resid_ps = compute_residuals_ps(sod(idx_sig), tof(idx_sig));
            histogram(ax, resid_ps, 60, 'FaceColor', colors_slot{slot}, ...
                'FaceAlpha',0.55,'EdgeColor','none', ...
                'DisplayName', get_station_label(crd));
        end
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9],...
            'Color',[0.15 0.16 0.18],'FontSize',9);
        ax.XLabel.String = 'Residual (ps)';
        ax.YLabel.String = 'Count';
        title(ax,'Residual Histogram','Color',[0.85 0.9 0.95],'FontSize',10);
        hold(ax,'off');
    end

    if show_rate
        plot_idx = plot_idx + 1;
        ax = nexttile(tl, max(1,ncols) + plot_idx);
        style_axes(ax); hold(ax,'on');
        for slot = 1:2
            if slot == 1, crd = app.crd1; else, crd = app.crd2; end
            if isempty(crd), continue; end
            [sod, ~, filter] = get_range_data(crd);
            if isempty(sod), continue; end
            % 10-second bins return rate
            bin_w = 10;
            edges = min(sod):bin_w:max(sod)+bin_w;
            n_total = histcounts(sod, edges);
            n_sig   = histcounts(sod(filter==2), edges);
            rate = 100 * n_sig ./ max(n_total,1);
            t_bin = edges(1:end-1) + bin_w/2;
            plot(ax, t_bin, rate, '.-','Color',colors_slot{slot},'LineWidth',1.2,...
                'MarkerSize',6,'DisplayName',get_station_label(crd));
        end
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9],...
            'Color',[0.15 0.16 0.18],'FontSize',9);
        ax.XLabel.String = 'Seconds of Day (s)';
        ax.YLabel.String = 'Return Rate (%)';
        ylim(ax,[0 100]);
        title(ax,'Return Rate (10-s bins)','Color',[0.85 0.9 0.95],'FontSize',10);
        hold(ax,'off');
    end
end

% =========================================================================
%  TAB: CALIBRATION
% =========================================================================
function fill_tab_calib(fig, tab)
    app = fig.UserData;
    have1 = ~isempty(app.crd1) && (isfield(app.crd1,'rec40')||isfield(app.crd1,'rec41'));
    have2 = ~isempty(app.crd2) && (isfield(app.crd2,'rec40')||isfield(app.crd2,'rec41'));
    if ~have1 && ~have2
        no_data_label(tab,'No calibration data available.');
        return;
    end

    g = uigridlayout(tab,[1 2]);
    g.BackgroundColor = [0.13 0.14 0.16];
    g.ColumnWidth = {'1x','1x'};
    g.Padding = [6 6 6 6];

    for slot = 1:2
        if slot == 1, crd = app.crd1; else, crd = app.crd2; end
        p = uipanel(g,'BackgroundColor',[0.15 0.16 0.18],'BorderType','none');
        p.Layout.Column = slot;
        if isempty(crd)
            uilabel(p,'Text','(no file)','FontColor',[0.4 0.5 0.6],...
                'FontSize',12,'HorizontalAlignment','center',...
                'Units','normalized','Position',[0 0 1 1],...
                'BackgroundColor',[0.15 0.16 0.18]);
            continue;
        end
        build_calib_panel(p, crd, slot);
    end
end

function build_calib_panel(panel, crd, slot)
    colors = {[0.22 0.55 0.80],[0.22 0.70 0.45]};
    hdrC = colors{slot};

    pg = uigridlayout(panel,[3 1]);
    pg.RowHeight = {26,'1x','1x'};
    pg.BackgroundColor = [0.15 0.16 0.18];
    pg.Padding = [6 6 6 6];

    uilabel(pg,'Text',sprintf('File %d — Calibration',slot),...
        'FontColor',hdrC,'FontWeight','bold','FontSize',13,...
        'BackgroundColor',[0.15 0.16 0.18]);

    % Text summary
    lines = calib_summary_lines(crd);
    uitextarea(pg,'Value',lines,'Editable','off',...
        'BackgroundColor',[0.10 0.11 0.13],...
        'FontColor',[0.82 0.88 0.95],'FontSize',11,'FontName','Courier New');

    % Calibration history plot (system delay over time if multiple records)
    ax = uiaxes(pg);
    style_axes(ax);
    plot_calib_history(ax, crd, hdrC);
end

function lines = calib_summary_lines(crd)
    lines = {};
    function addl(s), lines{end+1} = s; end
    function addkv(k,v), addl(sprintf('  %-28s %s', k, v)); end

    recs = {};
    if isfield(crd,'rec40') && ~isempty(crd.rec40), recs{end+1} = struct('type','Pre-pass (40)','data',crd.rec40); end
    if isfield(crd,'rec41') && ~isempty(crd.rec41), recs{end+1} = struct('type','Post-pass (41)','data',crd.rec41); end
    if isfield(crd,'rec42') && ~isempty(crd.rec42), recs{end+1} = struct('type','In-pass (42)','data',crd.rec42); end

    for kr = 1:numel(recs)
        addl(sprintf('─── %s (%d records) ', recs{kr}.type, size(recs{kr}.data,1)));
        d = recs{kr}.data;
        for k = 1:size(d,1)
            row = d(k,:);
            addl(sprintf('  Record #%d', k));
            addkv('  Config ID:',         row.config_id);
            addkv('  Sys delay (ps):',    fmt_na(row.sysdelay_ps));
            addkv('  Sys delay shift:',   fmt_na(row.sysdelay_shift));
            addkv('  RMS (ps):',          fmt_na(row.rms_ps));
            addkv('  Skew:',              fmt_na(row.skew));
            addkv('  Kurtosis:',          fmt_na(row.kurtosis));
            addkv('  Peak-Mean (ps):',    fmt_na(row.peak_mean_ps));
            addkv('  N firings:',         fmt_na(row.n_firings));
            addkv('  N returns:',         fmt_na(row.n_returns));
            addkv('  Return rate (%):',   fmt_na(row.return_rate_pct));
            addl('');
        end
    end
end

function plot_calib_history(ax, crd, color)
    hold(ax,'on');
    has_data = false;
    styles  = {'-o','--s',':^'};
    recs    = {};
    labels  = {};
    if isfield(crd,'rec40')&&~isempty(crd.rec40), recs{end+1}=crd.rec40; labels{end+1}='Pre (40)'; end
    if isfield(crd,'rec41')&&~isempty(crd.rec41), recs{end+1}=crd.rec41; labels{end+1}='Post (41)'; end
    if isfield(crd,'rec42')&&~isempty(crd.rec42), recs{end+1}=crd.rec42; labels{end+1}='In (42)'; end

    for kr = 1:numel(recs)
        d = recs{kr};
        sod = d.sod;
        sd  = d.sysdelay_ps;
        rms = d.rms_ps;
        valid = ~isnan(sd);
        if any(valid)
            errorbar(ax, sod(valid), sd(valid), rms(valid), rms(valid), ...
                styles{min(kr,numel(styles))}, 'Color', color, ...
                'MarkerFaceColor', color, 'MarkerSize', 6, ...
                'LineWidth', 1.2, 'DisplayName', labels{kr}, ...
                'CapSize', 4);
            has_data = true;
        end
    end
    if has_data
        ax.XLabel.String = 'Seconds of Day (s)';
        ax.YLabel.String = 'System Delay (ps)';
        ax.Title.String  = 'Calibration: System Delay ± RMS';
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9],...
            'Color',[0.15 0.16 0.18],'FontSize',9);
    else
        uilabel(ax.Parent,'Text','No numeric calibration data.', ...
            'FontColor',[0.6 0.7 0.8],'FontSize',11,...
            'HorizontalAlignment','center','Units','normalized',...
            'Position',[0.1 0.4 0.8 0.2],'BackgroundColor','none');
    end
    hold(ax,'off');
end

% =========================================================================
%  TAB: METEO
% =========================================================================
function fill_tab_meteo(fig, tab)
    app = fig.UserData;
    have1 = ~isempty(app.crd1) && isfield(app.crd1,'rec20') && ~isempty(app.crd1.rec20);
    have2 = ~isempty(app.crd2) && isfield(app.crd2,'rec20') && ~isempty(app.crd2.rec20);
    if ~have1 && ~have2
        no_data_label(tab,'No meteorological data (record 20) available.');
        return;
    end

    tl = tiledlayout(tab, 3, 1,'TileSpacing','compact','Padding','compact',...
        'BackgroundColor',[0.13 0.14 0.16]);

    fields_y = {'pressure_mbar','temp_K','humidity_pct'};
    ylabels  = {'Pressure (mbar)','Temperature (K)','Humidity (%)'};
    titles   = {'Atmospheric Pressure','Temperature','Relative Humidity'};
    colors   = {[0.22 0.65 0.95],[0.22 0.88 0.55]};

    for fi = 1:3
        ax = nexttile(tl);
        style_axes(ax);
        hold(ax,'on');
        for slot = 1:2
            if slot == 1, crd = app.crd1; else, crd = app.crd2; end
            if isempty(crd)||~isfield(crd,'rec20')||isempty(crd.rec20), continue; end
            d = crd.rec20;
            y = d.(fields_y{fi});
            valid = ~isnan(y);
            if ~any(valid), continue; end
            plot(ax, d.sod(valid), y(valid), '.-', 'Color', colors{slot}, ...
                'LineWidth', 1.2, 'MarkerSize', 5, 'DisplayName', get_station_label(crd));
        end
        ax.XLabel.String = 'Seconds of Day (s)';
        ax.YLabel.String = ylabels{fi};
        ax.Title.String  = titles{fi};
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9],...
            'Color',[0.15 0.16 0.18],'FontSize',9);
        hold(ax,'off');
    end
end

% =========================================================================
%  TAB: POINTING
% =========================================================================
function fill_tab_pointing(fig, tab)
    app = fig.UserData;
    have1 = ~isempty(app.crd1) && isfield(app.crd1,'rec30') && ~isempty(app.crd1.rec30);
    have2 = ~isempty(app.crd2) && isfield(app.crd2,'rec30') && ~isempty(app.crd2.rec30);
    if ~have1 && ~have2
        no_data_label(tab,'No pointing data (record 30) available.');
        return;
    end

    tl = tiledlayout(tab, 2, 2,'TileSpacing','compact','Padding','compact',...
        'BackgroundColor',[0.13 0.14 0.16]);
    colors = {[0.22 0.65 0.95],[0.22 0.88 0.55]};

    % Azimuth vs time
    ax1 = nexttile(tl);
    style_axes(ax1); hold(ax1,'on');
    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd)||~isfield(crd,'rec30')||isempty(crd.rec30), continue; end
        d = crd.rec30;
        plot(ax1,d.sod,d.azimuth,'.-','Color',colors{slot},'LineWidth',1,'MarkerSize',4,...
            'DisplayName',get_station_label(crd));
    end
    ax1.XLabel.String='Seconds of Day (s)'; ax1.YLabel.String='Azimuth (deg)';
    ax1.Title.String='Azimuth'; legend(ax1,'show','Location','best','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax1,'off');

    % Elevation vs time
    ax2 = nexttile(tl);
    style_axes(ax2); hold(ax2,'on');
    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd)||~isfield(crd,'rec30')||isempty(crd.rec30), continue; end
        d = crd.rec30;
        plot(ax2,d.sod,d.elevation,'.-','Color',colors{slot},'LineWidth',1,'MarkerSize',4,...
            'DisplayName',get_station_label(crd));
    end
    ax2.XLabel.String='Seconds of Day (s)'; ax2.YLabel.String='Elevation (deg)';
    ax2.Title.String='Elevation'; legend(ax2,'show','Location','best','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax2,'off');

    % Sky plot (polar: az vs el)
    ax3 = nexttile(tl);
    style_axes(ax3); hold(ax3,'on');
    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd)||~isfield(crd,'rec30')||isempty(crd.rec30), continue; end
        d = crd.rec30;
        az_rad = deg2rad(d.azimuth);
        el_deg = d.elevation;
        r = 90 - el_deg;
        [xp,yp] = pol2cart(az_rad - pi/2, r);
        scatter(ax3,xp,yp,5,colors{slot},'filled','DisplayName',get_station_label(crd));
    end
    % Draw elevation rings
    for el_ring = [30 60]
        theta = linspace(0,2*pi,360);
        r_ring = 90 - el_ring;
        plot(ax3, r_ring*cos(theta), r_ring*sin(theta), '--', ...
            'Color',[0.4 0.5 0.6],'LineWidth',0.7,'HandleVisibility','off');
        text(ax3, 0, -(r_ring)+2, sprintf('%d°',el_ring),'Color',[0.5 0.6 0.7],'FontSize',8,...
            'HorizontalAlignment','center');
    end
    axis(ax3,'equal'); ax3.Title.String='Sky Plot'; ax3.XAxis.Visible='off'; ax3.YAxis.Visible='off';
    legend(ax3,'show','Location','southoutside','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax3,'off');

    % Elevation vs range (if range available)
    ax4 = nexttile(tl);
    style_axes(ax4); hold(ax4,'on');
    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd)||~isfield(crd,'rec30')||isempty(crd.rec30), continue; end
        [sod_r,tof,~] = get_range_data(crd);
        if isempty(sod_r), continue; end
        d = crd.rec30;
        % Interpolate elevation at range epochs
        el_interp = interp1(d.sod, d.elevation, sod_r, 'linear','extrap');
        c_light = 299792458;
        range_m = tof * c_light / 2;
        scatter(ax4, range_m/1000, el_interp, 2, colors{slot},'filled','MarkerFaceAlpha',0.4,...
            'DisplayName',get_station_label(crd));
    end
    ax4.XLabel.String='Range (km)'; ax4.YLabel.String='Elevation (deg)';
    ax4.Title.String='Elevation vs Range'; legend(ax4,'show','Location','best','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax4,'off');
end

% =========================================================================
%  TAB: STATISTICS
% =========================================================================
function fill_tab_stats(fig, tab)
    app = fig.UserData;
    if isempty(app.crd1) && isempty(app.crd2)
        no_data_label(tab,'No data loaded.');
        return;
    end

    g = uigridlayout(tab,[2 2]);
    g.BackgroundColor = [0.13 0.14 0.16];
    g.RowHeight    = {'1x','1x'};
    g.ColumnWidth  = {'1x','1x'};
    g.Padding = [6 6 6 6];

    colors = {[0.22 0.55 0.80],[0.22 0.70 0.45]};

    for slot = 1:2
        crd = get_crd(app,slot);
        col = mod(slot-1,2)+1;
        row = 1;

        % Stats text
        p_text = uipanel(g,'BackgroundColor',[0.15 0.16 0.18],'BorderType','none');
        p_text.Layout.Row = row; p_text.Layout.Column = col;
        pg = uigridlayout(p_text,[2 1]);
        pg.RowHeight = {24,'1x'};
        pg.BackgroundColor = [0.15 0.16 0.18];
        pg.Padding=[4 4 4 4];
        uilabel(pg,'Text',sprintf('File %d — Statistics',slot),...
            'FontColor',colors{slot},'FontWeight','bold','FontSize',13,...
            'BackgroundColor',[0.15 0.16 0.18]);
        if ~isempty(crd)
            lines = compute_stats_lines(crd);
        else
            lines = {'(no file loaded)'};
        end
        uitextarea(pg,'Value',lines,'Editable','off',...
            'BackgroundColor',[0.10 0.11 0.13],...
            'FontColor',[0.82 0.88 0.95],'FontSize',11,'FontName','Courier New');
    end

    % Bottom row: comparison bar chart
    p_bar = uipanel(g,'BackgroundColor',[0.15 0.16 0.18],'BorderType','none');
    p_bar.Layout.Row = 2; p_bar.Layout.Column = [1 2];
    ax = uiaxes(p_bar,'Units','normalized','Position',[0.05 0.1 0.9 0.85]);
    style_axes(ax);
    build_stats_comparison_chart(ax, app, colors);
end

function lines = compute_stats_lines(crd)
    lines = {};
    function addl(s), lines{end+1} = s; end
    function addkv(k,v), addl(sprintf('  %-30s %s', k, v)); end

    addl('─── RANGE DATA STATISTICS ───');
    [sod, tof, filter] = get_range_data(crd);
    c_light = 299792458;
    if ~isempty(sod)
        range_m  = tof * c_light / 2;
        idx_sig  = filter == 2;
        if ~any(idx_sig), idx_sig = true(size(sod)); end
        r_sig    = range_m(idx_sig);
        tof_sig  = tof(idx_sig);
        sod_sig  = sod(idx_sig);
        resid_ps = compute_residuals_ps(sod_sig, tof_sig);

        addkv('Total records:',      num2str(numel(sod)));
        addkv('Signal records:',     num2str(sum(idx_sig)));
        addkv('Noise records:',      num2str(sum(~idx_sig)));
        addkv('Return rate (%):',    sprintf('%.2f', 100*sum(idx_sig)/numel(sod)));
        addkv('Min range (m):',      sprintf('%.3f', min(r_sig)));
        addkv('Max range (m):',      sprintf('%.3f', max(r_sig)));
        addkv('Mean range (m):',     sprintf('%.3f', mean(r_sig)));
        addl('');
        addl('─── RESIDUAL STATISTICS ───');
        addkv('RMS residual (ps):',  sprintf('%.2f', sqrt(mean(resid_ps.^2))));
        addkv('Mean residual (ps):', sprintf('%.2f', mean(resid_ps)));
        addkv('Std dev (ps):',       sprintf('%.2f', std(resid_ps)));
        addkv('Skewness:',           sprintf('%.4f', skewness(resid_ps)));
        addkv('Kurtosis:',           sprintf('%.4f', kurtosis(resid_ps)));
        addkv('P-P (ps):',           sprintf('%.2f', max(resid_ps)-min(resid_ps)));
        addkv('Pass duration (s):',  sprintf('%.1f', max(sod)-min(sod)));
    else
        addl('  No range data available.');
    end

    addl('');
    addl('─── SESSION STATS (Record 50) ───');
    if isfield(crd,'rec50') && ~isempty(crd.rec50)
        s = crd.rec50(1,:);
        addkv('Config ID:',     s.config_id);
        addkv('RMS (ps):',      fmt_na(s.rms_ps));
        addkv('Skew:',          fmt_na(s.skew));
        addkv('Kurtosis:',      fmt_na(s.kurtosis));
        addkv('Peak-Mean (ps):',fmt_na(s.peak_mean_ps));
    else
        addl('  No record 50 found.');
    end
end

function build_stats_comparison_chart(ax, app, colors)
    metrics_lbl = {'RMS (ps)','Skew','Kurtosis','Peak-Mean (ps)','Return Rate (%)'};
    vals = nan(2, numel(metrics_lbl));
    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd), continue; end
        [sod, tof, filter] = get_range_data(crd);
        if ~isempty(sod)
            idx_sig = filter == 2;
            if ~any(idx_sig), idx_sig = true(size(sod)); end
            resid_ps = compute_residuals_ps(sod(idx_sig), tof(idx_sig));
            vals(slot,1) = sqrt(mean(resid_ps.^2));
            vals(slot,2) = skewness(resid_ps);
            vals(slot,3) = kurtosis(resid_ps);
            vals(slot,4) = max(resid_ps)-min(resid_ps);
            vals(slot,5) = 100*sum(idx_sig)/numel(sod);
        end
        if isfield(crd,'rec50') && ~isempty(crd.rec50)
            s = crd.rec50(1,:);
            if ~isnan(s.rms_ps),         vals(slot,1) = s.rms_ps; end
            if ~isnan(s.skew),           vals(slot,2) = s.skew; end
            if ~isnan(s.kurtosis),       vals(slot,3) = s.kurtosis; end
            if ~isnan(s.peak_mean_ps),   vals(slot,4) = s.peak_mean_ps; end
        end
    end

    hold(ax,'on');
    x = 1:numel(metrics_lbl);
    bw = 0.35;
    for slot = 1:2
        xpos = x + (slot-1)*bw - bw/2;
        b = bar(ax, xpos, vals(slot,:), bw, 'FaceColor', colors{slot},...
            'EdgeColor','none','FaceAlpha',0.8);
        % Label with values
        for xi = 1:numel(xpos)
            if ~isnan(vals(slot,xi))
                text(ax, xpos(xi), vals(slot,xi)*1.02, sprintf('%.1f',vals(slot,xi)),...
                    'HorizontalAlignment','center','Color',colors{slot},'FontSize',8);
            end
        end
    end
    ax.XTick = x;
    ax.XTickLabel = metrics_lbl;
    ax.XTickLabelRotation = 15;
    ax.XLabel.String = '';
    ax.YLabel.String = 'Value';
    ax.Title.String  = 'Key Metrics Comparison (File 1 vs File 2)';
    legend(ax,{'File 1','File 2'},'Location','best','TextColor',[0.8 0.85 0.9],...
        'Color',[0.15 0.16 0.18],'FontSize',10);
    hold(ax,'off');
end

% =========================================================================
%  CRD v2 PARSER
% =========================================================================
function crd = parse_crd_v2(filename)
% parse_crd_v2  Parse an ILRS CRD v2 file into a structured MATLAB struct.
%
%  Fields populated (all optional, present only if records found):
%    .H1, .H2, .H3, .H4, .H5   — header structs
%    .C0, .C1, .C2, .C3, .C5, .C6, .C7   — config struct arrays
%    .rec10  — full-rate range data     (table: sod, tof, filter, ...)
%    .rec11  — normal-point data        (table)
%    .rec12  — mixed-rate data          (table)
%    .rec20  — meteorology data         (table)
%    .rec30  — pointing data            (table)
%    .rec40  — pre-pass calibration     (table)
%    .rec41  — post-pass calibration    (table)
%    .rec42  — in-pass calibration      (table)
%    .rec50  — session statistics       (table)
%    .comments — cell array of strings

    crd = struct();
    crd.filename = filename;

    fid = fopen(filename,'r','n','UTF-8');
    if fid == -1
        error('Cannot open file: %s', filename);
    end
    raw_lines = {};
    while ~feof(fid)
        raw_lines{end+1} = fgetl(fid); %#ok
    end
    fclose(fid);

    % Pre-allocate accumulators
    r10 = [];  r11 = [];  r12 = [];
    r20 = [];  r30 = [];
    r40 = [];  r41 = [];  r42 = [];
    r50 = [];
    comments = {};
    C0_list = {}; C1_list = {}; C2_list = {}; C3_list = {};
    C5_list = {}; C6_list = {}; C7_list = {};

    for li = 1:numel(raw_lines)
        line = strtrim(raw_lines{li});
        if isempty(line), continue; end

        tokens = strsplit(line);
        recid  = lower(tokens{1});

        switch recid
            case 'h1', crd.H1 = parse_H1(tokens);
            case 'h2', crd.H2 = parse_H2(tokens);
            case 'h3', crd.H3 = parse_H3(tokens);
            case 'h4', crd.H4 = parse_H4(tokens);
            case 'h5', crd.H5 = parse_H5(tokens);
            case 'h8', crd.H8 = parse_H8(tokens);
            case 'h9', % end of header — ignore
            case 'c0', C0_list{end+1} = parse_C0(tokens); %#ok
            case 'c1', C1_list{end+1} = parse_C1(tokens); %#ok
            case 'c2', C2_list{end+1} = parse_C2(tokens); %#ok
            case 'c3', C3_list{end+1} = parse_C3(tokens); %#ok
            case 'c5', C5_list{end+1} = parse_C5(tokens); %#ok
            case 'c6', C6_list{end+1} = parse_C6(tokens); %#ok
            case 'c7', C7_list{end+1} = parse_C7(tokens); %#ok
            case '10', r10 = [r10; parse_rec10(tokens)]; %#ok
            case '11', r11 = [r11; parse_rec11(tokens)]; %#ok
            case '12', r12 = [r12; parse_rec12(tokens)]; %#ok
            case '20', r20 = [r20; parse_rec20(tokens)]; %#ok
            case '30', r30 = [r30; parse_rec30(tokens)]; %#ok
            case '40', r40 = [r40; parse_rec40(tokens)]; %#ok
            case '41', r41 = [r41; parse_rec41(tokens)]; %#ok
            case '42', r42 = [r42; parse_rec42(tokens)]; %#ok
            case '50', r50 = [r50; parse_rec50(tokens)]; %#ok
            case '00', comments{end+1} = strjoin(tokens(2:end),' '); %#ok
            otherwise
                % skip unknown records
        end
    end

    % Store config lists
    if ~isempty(C0_list), crd.C0 = vertcat_structs(C0_list); end
    if ~isempty(C1_list), crd.C1 = vertcat_structs(C1_list); end
    if ~isempty(C2_list), crd.C2 = vertcat_structs(C2_list); end
    if ~isempty(C3_list), crd.C3 = vertcat_structs(C3_list); end
    if ~isempty(C5_list), crd.C5 = vertcat_structs(C5_list); end
    if ~isempty(C6_list), crd.C6 = vertcat_structs(C6_list); end
    if ~isempty(C7_list), crd.C7 = vertcat_structs(C7_list); end

    % Store data records
    if ~isempty(r10), crd.rec10 = struct_array_to_table(r10); end
    if ~isempty(r11), crd.rec11 = struct_array_to_table(r11); end
    if ~isempty(r12), crd.rec12 = struct_array_to_table(r12); end
    if ~isempty(r20), crd.rec20 = struct_array_to_table(r20); end
    if ~isempty(r30), crd.rec30 = struct_array_to_table(r30); end
    if ~isempty(r40), crd.rec40 = struct_array_to_table(r40); end
    if ~isempty(r41), crd.rec41 = struct_array_to_table(r41); end
    if ~isempty(r42), crd.rec42 = struct_array_to_table(r42); end
    if ~isempty(r50), crd.rec50 = struct_array_to_table(r50); end
    crd.comments = comments;
end

% ─── Header parsers ──────────────────────────────────────────────────────

function s = parse_H1(tok)
    % H1 CRD <version> <year> <month> <day> <hour>
    s.record_type   = 'H1';
    s.crd_version   = getnum(tok,3,2);
    s.year          = getnum(tok,4,0);
    s.month         = getnum(tok,5,0);
    s.day           = getnum(tok,6,0);
    s.hour          = getnum(tok,7,0);
end

function s = parse_H2(tok)
    % H2 <station_name> <cdp_pad_id> <cdp_sys_num> <cdp_occ_num> <timescale> <network>
    s.record_type   = 'H2';
    s.station_name  = getstr(tok,2,'unknown');
    s.cdp_pad_id    = getstr(tok,3,'0000');
    s.cdp_sys_num   = getnum(tok,4,0);
    s.cdp_occ_num   = getnum(tok,5,0);
    s.timescale     = getnum(tok,6,0);
    s.network       = getstr(tok,7,'ILRS');
end

function s = parse_H3(tok)
    % H3 <target_name> <ilrs_id> <sic> <norad> <sc_flag> <srp_flag> <sc_flag2>
    s.record_type   = 'H3';
    s.target_name   = getstr(tok,2,'unknown');
    s.ilrs_id       = getstr(tok,3,'0');
    s.sic           = getstr(tok,4,'0');
    s.norad         = getstr(tok,5,'0');
    s.sc_flag       = getnum(tok,6,0);
    s.srp_flag      = getnum(tok,7,0);
    s.reflectivity  = getnum(tok,8,0);
end

function s = parse_H4(tok)
    % H4 <data_type> <start YYYY MM DD HH MM SS> <end YYYY MM DD HH MM SS>
    %    <sysdelay_applied> <tropo_applied> <com_applied> <xcm_applied>
    %    <data_release> <ranging_mode>
    s.record_type      = 'H4';
    s.data_type        = getnum(tok,2,0);
    s.start_year       = getnum(tok,3,0);
    s.start_month      = getnum(tok,4,0);
    s.start_day        = getnum(tok,5,0);
    s.start_hour       = getnum(tok,6,0);
    s.start_min        = getnum(tok,7,0);
    s.start_sec        = getnum(tok,8,0);
    s.end_year         = getnum(tok,9,0);
    s.end_month        = getnum(tok,10,0);
    s.end_day          = getnum(tok,11,0);
    s.end_hour         = getnum(tok,12,0);
    s.end_min          = getnum(tok,13,0);
    s.end_sec          = getnum(tok,14,0);
    s.sysdelay_applied = getnum(tok,15,0);
    s.tropo_applied    = getnum(tok,16,0);
    s.com_applied      = getnum(tok,17,0);
    s.xcm_applied      = getnum(tok,18,0);
    s.data_release     = getnum(tok,19,0);
    s.ranging_mode     = getnum(tok,21,0);
end

function s = parse_H5(tok)
    s.record_type      = 'H5';
    s.pred_type        = getnum(tok,2,0);
    s.pred_file_name   = getstr(tok,3,'na');
    s.pred_pnt_epoch   = getnum(tok,4,NaN);
    s.pred_interval_s  = getnum(tok,5,NaN);
end

function s = parse_H8(tok)
    s.record_type = 'H8';
    s.raw = strjoin(tok(2:end),' ');
end

% ─── Configuration parsers ───────────────────────────────────────────────

function s = parse_C0(tok)
    % C0 <detail_type> <wavelength_nm> <config_id> <laser_id> <detector_id>
    %    <timer_id> <timer_network_id> <epoch_delay_shift_id>
    s.record_type   = 'C0';
    s.detail_type   = getnum(tok,2,0);
    s.wavelength_nm = getnum(tok,3,NaN);
    s.config_id     = getstr(tok,4,'na');
    s.laser_id      = getstr(tok,5,'na');
    s.detector_id   = getstr(tok,6,'na');
    s.timer_id      = getstr(tok,7,'na');
    s.meteo_id      = getstr(tok,8,'na');
    s.cal_id        = getstr(tok,9,'na');
end

function s = parse_C1(tok)
    % C1 <detail_type> <laser_id> <laser_type> <wavelength_nm>
    %    <nom_fire_rate> <pulse_energy_mJ> <pulse_width_ps> <beam_div_urad> <pulses_in_semitr>
    s.record_type      = 'C1';
    s.detail_type      = getnum(tok,2,0);
    s.laser_id         = getstr(tok,3,'na');
    s.laser_type       = getstr(tok,4,'na');
    s.wavelength_nm    = getnum(tok,5,NaN);
    s.nom_fire_rate    = getnum(tok,6,NaN);
    s.pulse_energy_mJ  = getnum(tok,7,NaN);
    s.pulse_width_ps   = getnum(tok,8,NaN);
    s.beam_div_urad    = getnum(tok,9,NaN);
    s.pulses_semitrain = getnum(tok,10,NaN);
end

function s = parse_C2(tok)
    % C2 <detail_type> <detector_id> <detector_type> <wavelength_nm>
    %    <qe_pct> <voltage_V> <dark_count_kHz> <output_pulse_type>
    %    <output_pulse_width_ps> <spectral_filter_nm> <spectral_filter_fwhm_nm>
    %    <spatial_filter_arcsec> <ext_signal_proc> <amp_in_ps> <amp_out_ps> <amp_chain_id>
    s.record_type          = 'C2';
    s.detail_type          = getnum(tok,2,0);
    s.detector_id          = getstr(tok,3,'na');
    s.detector_type        = getstr(tok,4,'na');
    s.wavelength_nm        = getnum(tok,5,NaN);
    s.qe_pct               = getnum(tok,6,NaN);
    s.voltage_V            = getnum(tok,7,NaN);
    s.dark_count_kHz       = getnum(tok,8,NaN);
    s.output_pulse_type    = getstr(tok,9,'na');
    s.output_pulse_width   = getnum(tok,10,NaN);
    s.spectral_filter_nm   = getnum(tok,11,NaN);
    s.spectral_fwhm_nm     = getnum(tok,12,NaN);
    s.spatial_filter_arcsec= getnum(tok,13,NaN);
    s.ext_signal_proc      = getstr(tok,14,'na');
    s.amp_in_ps            = getnum(tok,15,NaN);
    s.amp_out_ps           = getnum(tok,16,NaN);
end

function s = parse_C3(tok)
    % C3 <detail_type> <timer_id> <timer_name> <freq_MHz> <time_resolution_ps> <accuracy_corr>
    s.record_type        = 'C3';
    s.detail_type        = getnum(tok,2,0);
    s.timer_id           = getstr(tok,3,'na');
    s.timer_name         = getstr(tok,4,'na');
    s.freq_MHz           = getnum(tok,5,NaN);
    s.time_resolution_ps = getnum(tok,6,NaN);
    s.accuracy_corr      = getnum(tok,7,NaN);
end

function s = parse_C5(tok)
    % C5 meteorology sensor
    s.record_type  = 'C5';
    s.detail_type  = getnum(tok,2,0);
    s.meteo_id     = getstr(tok,3,'na');
    s.pres_uncert  = getnum(tok,4,NaN);
    s.temp_uncert  = getnum(tok,5,NaN);
    s.humid_uncert = getnum(tok,6,NaN);
end

function s = parse_C6(tok)
    % C6 calibration target
    s.record_type  = 'C6';
    s.detail_type  = getnum(tok,2,0);
    s.cal_id       = getstr(tok,3,'na');
    s.range_m      = getnum(tok,4,NaN);
end

function s = parse_C7(tok)
    % C7 transponder
    s.record_type  = 'C7';
    s.raw          = strjoin(tok(2:end),' ');
end

% ─── Data record parsers ─────────────────────────────────────────────────

function s = parse_rec10(tok)
    % 10 <sod> <tof_s> <sysconf_id> <epoch_event> <filter_flag>
    %    <detector_ch> <stop_num> [<rx_amp>] [<tx_amp>]
    s.sod           = getnum(tok,2,NaN);
    s.tof           = getnum(tok,3,NaN);
    s.config_id     = getstr(tok,4,'na');
    s.epoch_event   = getnum(tok,5,0);
    s.filter_flag   = getnum(tok,6,0);
    s.detector_ch   = getnum(tok,7,NaN);
    s.stop_num      = getnum(tok,8,NaN);
    s.rx_amp        = getnum(tok,9,NaN);
    s.tx_amp        = getnum(tok,10,NaN);
end

function s = parse_rec11(tok)
    % 11 <sod> <tof_s> <sysconf_id> <epoch_event> <NP_window_s>
    %    <N_raw> <bin_RMS_ps> <skew> <kurtosis> <peak_mean_ps>
    %    <return_rate_pct> [<detector_ch>] [<SNR>]
    s.sod             = getnum(tok,2,NaN);
    s.tof             = getnum(tok,3,NaN);
    s.config_id       = getstr(tok,4,'na');
    s.epoch_event     = getnum(tok,5,0);
    s.np_window_s     = getnum(tok,6,NaN);
    s.n_raw           = getnum(tok,7,NaN);
    s.bin_rms_ps      = getnum(tok,8,NaN);
    s.skew            = getnum(tok,9,NaN);
    s.kurtosis        = getnum(tok,10,NaN);
    s.peak_mean_ps    = getnum(tok,11,NaN);
    s.return_rate_pct = getnum(tok,12,NaN);
    s.detector_ch     = getnum(tok,13,NaN);
    s.snr             = getnum(tok,14,NaN);
end

function s = parse_rec12(tok)
    % 12 mixed rate — same layout as 10 with additional NP fields
    s = parse_rec10(tok);
    s.np_window_s     = getnum(tok,11,NaN);
    s.n_raw           = getnum(tok,12,NaN);
    s.bin_rms_ps      = getnum(tok,13,NaN);
    s.return_rate_pct = getnum(tok,14,NaN);
end

function s = parse_rec20(tok)
    % 20 <sod> <pressure_mbar> <temp_K> <humidity_pct> <origin_flag>
    s.sod           = getnum(tok,2,NaN);
    s.pressure_mbar = getnum(tok,3,NaN);
    s.temp_K        = getnum(tok,4,NaN);
    s.humidity_pct  = getnum(tok,5,NaN);
    s.origin_flag   = getnum(tok,6,NaN);
end

function s = parse_rec30(tok)
    % 30 <sod> <azimuth_deg> <elevation_deg> <direction_flag> <origin_flag>
    %    [<azimuth_rate>] [<elevation_rate>]
    s.sod            = getnum(tok,2,NaN);
    s.azimuth        = getnum(tok,3,NaN);
    s.elevation      = getnum(tok,4,NaN);
    s.direction_flag = getnum(tok,5,NaN);
    s.origin_flag    = getnum(tok,6,NaN);
    s.az_rate        = getnum(tok,7,NaN);
    s.el_rate        = getnum(tok,8,NaN);
end

function s = parse_rec40(tok)
    s = parse_calib_common(tok);
    s.type = 40;
end

function s = parse_rec41(tok)
    s = parse_calib_common(tok);
    s.type = 41;
end

function s = parse_rec42(tok)
    s = parse_calib_common(tok);
    s.type = 42;
end

function s = parse_calib_common(tok)
    % 40/41/42 <sod> <type_flag> <config_id>
    %   <n_firings> <n_returns> <return_rate_pct>
    %   <sysdelay_ps> <sysdelay_shift_ps> <rms_ps>
    %   <skew> <kurtosis> <peak_mean_ps>
    %   <cal_type_flag> <cal_shift_flag> <noise_flag> <window_flag> <return_rate_flag>
    s.sod               = getnum(tok,2,NaN);
    s.type_flag         = getnum(tok,3,0);
    s.config_id         = getstr(tok,4,'na');
    s.n_firings         = getnum(tok,5,NaN);
    s.n_returns         = getnum(tok,6,NaN);
    s.return_rate_pct   = getnum(tok,7,NaN);
    s.sysdelay_ps       = getnum(tok,8,NaN);
    s.sysdelay_shift    = getnum(tok,9,NaN);
    s.rms_ps            = getnum(tok,10,NaN);
    s.skew              = getnum(tok,11,NaN);
    s.kurtosis          = getnum(tok,12,NaN);
    s.peak_mean_ps      = getnum(tok,13,NaN);
    s.cal_type_flag     = getnum(tok,14,NaN);
    s.cal_shift_flag    = getnum(tok,15,NaN);
    s.noise_flag        = getnum(tok,16,NaN);
    s.window_flag       = getnum(tok,17,NaN);
    s.return_rate_flag  = getnum(tok,18,NaN);
end

function s = parse_rec50(tok)
    % 50 <config_id> <rms_ps> <skew> <kurtosis> <peak_mean_ps> <data_qual_flag>
    s.config_id     = getstr(tok,2,'na');
    s.rms_ps        = getnum(tok,3,NaN);
    s.skew          = getnum(tok,4,NaN);
    s.kurtosis      = getnum(tok,5,NaN);
    s.peak_mean_ps  = getnum(tok,6,NaN);
    s.data_qual_flag= getnum(tok,7,NaN);
end

% ─── Helper: safe token extractors ───────────────────────────────────────

function v = getnum(tok, idx, default)
    if idx > numel(tok)
        v = default; return;
    end
    t = lower(strtrim(tok{idx}));
    if strcmp(t,'na') || strcmp(t,'n/a') || isempty(t)
        v = NaN; return;
    end
    v = str2double(t);
    if isnan(v)
        v = default;
    end
end

function v = getstr(tok, idx, default)
    if idx > numel(tok)
        v = default; return;
    end
    v = strtrim(tok{idx});
    if isempty(v), v = default; end
end

% ─── Struct/table helpers ─────────────────────────────────────────────────

function out = vertcat_structs(list)
    % Convert cell array of structs with same fields to struct array
    out = list{1};
    for k = 2:numel(list)
        out(end+1) = list{k}; %#ok
    end
end

function T = struct_array_to_table(sarr)
    % Convert struct array to table, dropping non-numeric/string scalar fields
    % that can't be column-concatenated (e.g., variable-length char arrays)
    try
        T = struct2table(sarr, 'AsArray', true);
    catch
        % Fallback: build table field by field
        T = table();
        fns = fieldnames(sarr);
        for k = 1:numel(fns)
            fn = fns{k};
            vals = {sarr.(fn)};
            % Try to convert to numeric column
            nums = cellfun(@(v) double(v(1)), vals, 'UniformOutput', false);
            try
                T.(fn) = cell2mat(nums)';
            catch
                T.(fn) = vals';
            end
        end
    end
end

% =========================================================================
%  UTILITY FUNCTIONS
% =========================================================================

function [sod, tof, filter] = get_range_data(crd)
    sod = []; tof = []; filter = [];
    if isfield(crd,'rec10') && ~isempty(crd.rec10)
        sod    = crd.rec10.sod;
        tof    = crd.rec10.tof;
        filter = crd.rec10.filter_flag;
    elseif isfield(crd,'rec11') && ~isempty(crd.rec11)
        sod    = crd.rec11.sod;
        tof    = crd.rec11.tof;
        filter = ones(size(sod)) * 2;  % NP data is always signal
    elseif isfield(crd,'rec12') && ~isempty(crd.rec12)
        sod    = crd.rec12.sod;
        tof    = crd.rec12.tof;
        filter = crd.rec12.filter_flag;
    end
    if ~isempty(sod)
        valid = ~isnan(sod) & ~isnan(tof);
        sod    = sod(valid);
        tof    = tof(valid);
        filter = filter(valid);
    end
end

function resid_ps = compute_residuals_ps(sod, tof)
    % Fit a low-degree polynomial to TOF vs time, return ps residuals
    c_light = 299792458;  % m/s
    if numel(sod) < 4
        resid_ps = zeros(size(sod));
        return;
    end
    sod_norm = (sod - mean(sod)) / max(std(sod),1);
    deg = min(6, floor(numel(sod)/10));
    deg = max(deg, 2);
    p   = polyfit(sod_norm, tof, deg);
    tof_fit = polyval(p, sod_norm);
    resid_s = tof - tof_fit;
    resid_ps = resid_s * c_light * 1e12;  % convert to picoseconds (one-way)
end

function label = get_station_label(crd)
    if isfield(crd,'H2')
        label = sprintf('%s/%s', crd.H2.station_name, crd.H2.cdp_pad_id);
    else
        label = 'Unknown';
    end
end

function crd = get_crd(app, slot)
    if slot == 1, crd = app.crd1;
    else,          crd = app.crd2; end
end

function s = fmt_na(v)
    if isnan(v), s = 'na';
    else,         s = sprintf('%.4g', v); end
end

function no_data_label(tab, msg)
    uilabel(tab,'Text',msg,...
        'FontColor',[0.5 0.6 0.7],'FontSize',13,...
        'HorizontalAlignment','center','VerticalAlignment','center',...
        'Units','normalized','Position',[0.1 0.4 0.8 0.2],...
        'BackgroundColor',[0.13 0.14 0.16]);
end

function style_axes(ax)
    ax.Color            = [0.10 0.11 0.13];
    ax.XColor           = [0.65 0.72 0.80];
    ax.YColor           = [0.65 0.72 0.80];
    ax.GridColor        = [0.25 0.28 0.32];
    ax.MinorGridColor   = [0.18 0.20 0.23];
    ax.GridAlpha        = 0.4;
    ax.XGrid            = 'on';
    ax.YGrid            = 'on';
    ax.Box              = 'on';
    ax.Title.Color      = [0.85 0.90 0.95];
    ax.Title.FontSize   = 11;
    ax.XLabel.Color     = [0.70 0.78 0.88];
    ax.YLabel.Color     = [0.70 0.78 0.88];
    ax.FontSize         = 10;
    ax.TickDir          = 'out';
end
