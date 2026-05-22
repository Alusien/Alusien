function CRD_Viewer()
% CRD_Viewer  Interactive GUI for ILRS CRD v2 files (.fr2 / .np2)
%
% Usage: CRD_Viewer()
%
% Supports CRD v2.01 (case-insensitive record IDs, "na" fields = NaN)
% Load up to two files for side-by-side station comparison.
% Requires MATLAB R2019b or later.

    fig = uifigure('Name','ILRS CRD v2 Viewer', ...
                   'Position',[50 50 1400 850], ...
                   'Color',[0.13 0.14 0.16], ...
                   'Resize','on');

    app.fig   = fig;
    app.crd1  = [];
    app.crd2  = [];
    app.file1 = '';
    app.file2 = '';
    fig.UserData = app;

    mainGrid = uigridlayout(fig, [1 2]);
    mainGrid.ColumnWidth = {260, '1x'};
    mainGrid.BackgroundColor = [0.13 0.14 0.16];

    leftPanel = uipanel(mainGrid, ...
        'BackgroundColor',[0.17 0.18 0.20], ...
        'BorderType','none');
    leftPanel.Layout.Column = 1;

    tabGroup = uitabgroup(mainGrid);
    tabGroup.Layout.Column = 2;
    fig.UserData.tabGroup = tabGroup;

    build_left_panel(fig, leftPanel);

    tabs = build_tabs(tabGroup);
    fig.UserData.tabs = tabs;

    show_placeholder(tabs);

end

% =========================================================================
%  LEFT PANEL
% =========================================================================
function build_left_panel(fig, panel)
    g = uigridlayout(panel, [12 1]);
    g.RowHeight   = {30, 30, 8, 30, 30, 8, 8, 180, 8, '1x', 30, 30};
    g.ColumnWidth = {'1x'};
    g.BackgroundColor = [0.17 0.18 0.20];
    g.Padding = [10 10 10 10];
    g.RowSpacing = 4;

    lbl_style = {'FontColor',[0.8 0.85 0.9],'FontSize',11,'FontWeight','bold', ...
                 'BackgroundColor',[0.17 0.18 0.20],'HorizontalAlignment','left'};

    uilabel(g, lbl_style{:}, 'Text','File 1 (Primary)');
    uibutton(g, 'Text','Load File 1 (.fr2 / .np2)', ...
        'BackgroundColor',[0.22 0.55 0.80], ...
        'FontColor','white','FontWeight','bold', ...
        'ButtonPushedFcn', @(~,~) cb_load_file(fig,1));

    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]);

    uilabel(g, lbl_style{:}, 'Text','File 2 (Comparison, optional)');
    uibutton(g, 'Text','Load File 2 (.fr2 / .np2)', ...
        'BackgroundColor',[0.22 0.70 0.45], ...
        'FontColor','white','FontWeight','bold', ...
        'ButtonPushedFcn', @(~,~) cb_load_file(fig,2));

    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]);
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]);

    infoBox = uitextarea(g, ...
        'Value',{'No file loaded.','','Use the buttons above','to open CRD v2 files.'}, ...
        'Editable','off', ...
        'BackgroundColor',[0.12 0.13 0.15], ...
        'FontColor',[0.65 0.75 0.85], ...
        'FontSize',10);
    fig.UserData.infoBox = infoBox;

    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]);
    uilabel(g,'Text','','BackgroundColor',[0.17 0.18 0.20]);

    uilabel(g,'Text','ILRS CRD v2 Viewer', ...
        'FontColor',[0.4 0.5 0.6],'FontSize',9,'BackgroundColor',[0.17 0.18 0.20]);
    uilabel(g,'Text','Station QC Tool', ...
        'FontColor',[0.3 0.4 0.5],'FontSize',9,'BackgroundColor',[0.17 0.18 0.20]);
end

% =========================================================================
%  TABS
% =========================================================================
function tabs = build_tabs(tabGroup)
    names  = {'Overview','Range & Residuals','Calibration','Meteo','Pointing','Statistics'};
    fnames = {'overview','range','calib','meteo','pointing','stats'};
    tabs   = struct();
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
        g = uigridlayout(t,[1 1]);
        g.BackgroundColor = [0.13 0.14 0.16];
        uilabel(g,'Text','Load a CRD file to display data.', ...
            'FontColor',[0.5 0.6 0.7],'FontSize',14, ...
            'HorizontalAlignment','center','VerticalAlignment','center', ...
            'BackgroundColor',[0.13 0.14 0.16]);
    end
end

% =========================================================================
%  FILE LOAD CALLBACK
% =========================================================================
function cb_load_file(fig, slot)
    app = fig.UserData;
    [fname, fpath] = uigetfile( ...
        {'*.fr2;*.np2','CRD v2 Files (*.fr2,*.np2)';'*.*','All Files (*.*)'}, ...
        'Select CRD v2 File');
    if isequal(fname,0), return; end
    fullpath = fullfile(fpath, fname);

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

    update_info_box(fig);
    refresh_all_tabs(fig);
end

% =========================================================================
%  INFO BOX
% =========================================================================
function update_info_box(fig)
    app = fig.UserData;
    lines = {};
    for slot = 1:2
        if slot == 1, crd = app.crd1; prefix = 'File 1';
        else,          crd = app.crd2; prefix = 'File 2'; end
        if isempty(crd), continue; end
        lines{end+1} = sprintf('=== %s ===', prefix); %#ok
        if isfield(crd,'H2')
            lines{end+1} = sprintf('Station: %s (CDP %s)', ...
                crd.H2.station_name, crd.H2.cdp_pad_id); %#ok
        end
        if isfield(crd,'H3')
            lines{end+1} = sprintf('Target:  %s', crd.H3.target_name); %#ok
        end
        if isfield(crd,'H4')
            lines{end+1} = sprintf('Start: %04d-%02d-%02d %02d:%02d:%02d', ...
                crd.H4.start_year, crd.H4.start_month, crd.H4.start_day, ...
                crd.H4.start_hour, crd.H4.start_min, crd.H4.start_sec); %#ok
            lines{end+1} = sprintf('End:   %04d-%02d-%02d %02d:%02d:%02d', ...
                crd.H4.end_year, crd.H4.end_month, crd.H4.end_day, ...
                crd.H4.end_hour, crd.H4.end_min, crd.H4.end_sec); %#ok
        end
        if isfield(crd,'rec10') && ~isempty(crd.rec10)
            lines{end+1} = sprintf('Rec10: %d', height(crd.rec10)); %#ok
        end
        if isfield(crd,'rec11') && ~isempty(crd.rec11)
            lines{end+1} = sprintf('Rec11: %d', height(crd.rec11)); %#ok
        end
        lines{end+1} = ''; %#ok
    end
    if isempty(lines), lines = {'No file loaded.'}; end
    app.infoBox.Value = lines;
end

% =========================================================================
%  REFRESH ALL TABS
% =========================================================================
function refresh_all_tabs(fig)
    app  = fig.UserData;
    tabs = app.tabs;
    fns  = fieldnames(tabs);
    for k = 1:numel(fns)
        delete(tabs.(fns{k}).Children);
    end
    fill_tab_overview(fig, tabs.overview);
    fill_tab_range(fig,    tabs.range);
    fill_tab_calib(fig,    tabs.calib);
    fill_tab_meteo(fig,    tabs.meteo);
    fill_tab_pointing(fig, tabs.pointing);
    fill_tab_stats(fig,    tabs.stats);
end

% =========================================================================
%  TAB: OVERVIEW
% =========================================================================
function fill_tab_overview(fig, tab)
    app = fig.UserData;
    if isempty(app.crd1) && isempty(app.crd2)
        no_data_label(tab,'No data loaded.'); return;
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
            g2 = uigridlayout(col_panel,[1 1]);
            g2.BackgroundColor = [0.15 0.16 0.18];
            uilabel(g2,'Text','(no file)','FontColor',[0.4 0.5 0.6], ...
                'FontSize',12,'HorizontalAlignment','center', ...
                'VerticalAlignment','center','BackgroundColor',[0.15 0.16 0.18]);
            continue;
        end
        build_overview_panel(col_panel, crd, slot);
    end
end

function build_overview_panel(panel, crd, slot)
    colors = {[0.22 0.55 0.80],[0.22 0.70 0.45]};
    hdrColor = colors{slot};

    g = uigridlayout(panel,[2 1]);
    g.RowHeight = {26,'1x'};
    g.BackgroundColor = [0.15 0.16 0.18];
    g.Padding = [6 6 6 6];

    uilabel(g,'Text',sprintf('File %d - Station Overview', slot), ...
        'FontColor',hdrColor,'FontWeight','bold','FontSize',13, ...
        'BackgroundColor',[0.15 0.16 0.18]);

    uitextarea(g,'Value',crd_to_overview_lines(crd),'Editable','off', ...
        'BackgroundColor',[0.10 0.11 0.13], ...
        'FontColor',[0.82 0.88 0.95], ...
        'FontSize',11,'FontName','Courier New');
end

function lines = crd_to_overview_lines(crd)
    lines = {};
    function addl(s),    lines{end+1} = s; end %#ok
    function addkv(k,v), addl(sprintf('  %-26s %s', k, v)); end %#ok
    function sep(title_str), addl(''); addl(['--- ' title_str ' ---']); end %#ok

    sep('SESSION HEADER');
    if isfield(crd,'H1')
        addkv('Format:', sprintf('CRD v%d  %04d-%02d-%02d', ...
            crd.H1.crd_version, crd.H1.year, crd.H1.month, crd.H1.day));
    end
    if isfield(crd,'H2')
        addkv('Station:',    crd.H2.station_name);
        addkv('CDP Pad ID:', crd.H2.cdp_pad_id);
        addkv('CDP Sys ID:', num2str(crd.H2.cdp_sys_num));
        addkv('Timescale:',  num2str(crd.H2.timescale));
        addkv('Network:',    crd.H2.network);
    end
    if isfield(crd,'H3')
        sep('TARGET');
        addkv('Name:',    crd.H3.target_name);
        addkv('ILRS ID:', crd.H3.ilrs_id);
        addkv('SIC:',     crd.H3.sic);
        addkv('NORAD:',   crd.H3.norad);
    end
    if isfield(crd,'H4')
        sep('PASS TIMES');
        addkv('Start:', sprintf('%04d-%02d-%02d %02d:%02d:%02d UTC', ...
            crd.H4.start_year,crd.H4.start_month,crd.H4.start_day, ...
            crd.H4.start_hour,crd.H4.start_min,crd.H4.start_sec));
        addkv('End:',   sprintf('%04d-%02d-%02d %02d:%02d:%02d UTC', ...
            crd.H4.end_year,crd.H4.end_month,crd.H4.end_day, ...
            crd.H4.end_hour,crd.H4.end_min,crd.H4.end_sec));
        addkv('Sysdelay applied:', num2str(crd.H4.sysdelay_applied));
        addkv('Tropo applied:',    num2str(crd.H4.tropo_applied));
        addkv('CoM applied:',      num2str(crd.H4.com_applied));
    end
    if isfield(crd,'C0') && ~isempty(crd.C0)
        sep('SYSTEM CONFIG (C0)');
        for k = 1:numel(crd.C0)
            c = crd.C0(k);
            addkv(sprintf('Config[%d]:',c.detail_type), ...
                sprintf('%s  wl=%.2f nm', c.config_id, c.wavelength_nm));
        end
    end
    if isfield(crd,'C1') && ~isempty(crd.C1)
        sep('LASER (C1)');
        for k = 1:numel(crd.C1)
            c = crd.C1(k);
            addkv(sprintf('[%s] Type:',c.laser_id), c.laser_type);
            addkv('  Wavelength (nm):',   num2str(c.wavelength_nm));
            addkv('  Rep rate (Hz):',     num2str(c.nom_fire_rate));
            addkv('  Pulse energy (mJ):', num2str(c.pulse_energy_mJ));
            addkv('  Pulse width (ps):',  num2str(c.pulse_width_ps));
        end
    end
    if isfield(crd,'C2') && ~isempty(crd.C2)
        sep('DETECTOR (C2)');
        for k = 1:numel(crd.C2)
            c = crd.C2(k);
            addkv(sprintf('[%s] Type:',c.detector_id), c.detector_type);
            addkv('  Wavelength (nm):', num2str(c.wavelength_nm));
            addkv('  QE (%):', num2str(c.qe_pct));
        end
    end
    if isfield(crd,'C3') && ~isempty(crd.C3)
        sep('TIMING (C3)');
        for k = 1:numel(crd.C3)
            c = crd.C3(k);
            addkv(sprintf('[%s] Freq (MHz):',c.timer_id), num2str(c.freq_MHz));
            addkv('  Resolution (ps):', num2str(c.time_resolution_ps));
        end
    end
    sep('DATA COUNTS');
    if isfield(crd,'rec10'), addkv('Full-rate (10):',    num2str(height(crd.rec10))); end
    if isfield(crd,'rec11'), addkv('Normal-point (11):', num2str(height(crd.rec11))); end
    if isfield(crd,'rec12'), addkv('Mixed-rate (12):',   num2str(height(crd.rec12))); end
    if isfield(crd,'rec20'), addkv('Meteo (20):',        num2str(height(crd.rec20))); end
    if isfield(crd,'rec30'), addkv('Pointing (30):',     num2str(height(crd.rec30))); end
    if isfield(crd,'rec40'), addkv('Cal pre (40):',      num2str(height(crd.rec40))); end
    if isfield(crd,'rec41'), addkv('Cal post (41):',     num2str(height(crd.rec41))); end
    if isfield(crd,'rec50'), addkv('Session stats (50):',num2str(height(crd.rec50))); end
end

% =========================================================================
%  TAB: RANGE & RESIDUALS
% =========================================================================
function fill_tab_range(fig, tab)
    app = fig.UserData;
    have1 = ~isempty(app.crd1) && ...
            (isfield(app.crd1,'rec10')||isfield(app.crd1,'rec11'));
    have2 = ~isempty(app.crd2) && ...
            (isfield(app.crd2,'rec10')||isfield(app.crd2,'rec11'));
    if ~have1 && ~have2
        no_data_label(tab,'No range data available.'); return;
    end

    og = uigridlayout(tab,[2 1]);
    og.RowHeight = {32,'1x'};
    og.BackgroundColor = [0.13 0.14 0.16];
    og.Padding = [4 4 4 4];

    tbRow = uigridlayout(og,[1 8]);
    tbRow.Layout.Row = 1;
    tbRow.BackgroundColor = [0.13 0.14 0.16];
    tbRow.ColumnWidth = {100,90,90,90,90,90,80,'1x'};

    uilabel(tbRow,'Text','Show:','FontColor',[0.8 0.85 0.9],'FontSize',11, ...
        'BackgroundColor',[0.13 0.14 0.16]);
    cb_raw  = uicheckbox(tbRow,'Text','Raw TOF','Value',1, ...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_sig  = uicheckbox(tbRow,'Text','Signal only','Value',0, ...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_res  = uicheckbox(tbRow,'Text','Residuals','Value',1, ...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_hist = uicheckbox(tbRow,'Text','Histogram','Value',1, ...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    cb_rate = uicheckbox(tbRow,'Text','Ret.rate','Value',1, ...
        'FontColor',[0.8 0.85 0.9],'BackgroundColor',[0.13 0.14 0.16]);
    btnRefresh = uibutton(tbRow,'Text','Refresh','FontWeight','bold', ...
        'BackgroundColor',[0.3 0.35 0.4],'FontColor','white');
    uilabel(tbRow,'Text','','BackgroundColor',[0.13 0.14 0.16]);

    plotPanel = uipanel(og,'BackgroundColor',[0.13 0.14 0.16],'BorderType','none');
    plotPanel.Layout.Row = 2;

    cbopts = struct('raw',cb_raw,'signal',cb_sig,'resid',cb_res, ...
                    'hist',cb_hist,'rate',cb_rate);
    draw_range_plots(fig, plotPanel, cbopts);

    btnRefresh.ButtonPushedFcn = @(~,~) draw_range_plots(fig, plotPanel, cbopts);
end

function draw_range_plots(fig, panel, opts)
    app = fig.UserData;
    delete(panel.Children);

    show_raw   = opts.raw.Value;
    sig_only   = opts.signal.Value;
    show_resid = opts.resid.Value;
    show_hist  = opts.hist.Value;
    show_rate  = opts.rate.Value;

    nbot    = show_resid + show_hist + show_rate;
    has_bot = nbot > 0;

    if has_bot, y1 = 0.50; h1 = 0.46;
    else,        y1 = 0.07; h1 = 0.89; end

    ax1 = uiaxes(panel,'Units','normalized','Position',[0.07 y1 0.88 h1]);
    style_axes(ax1);
    hold(ax1,'on');
    ax1.XLabel.String = 'Seconds of Day (s)';
    ax1.YLabel.String = 'Range (m)';
    ax1.Title.String  = 'One-Way Range vs Time';

    colors_sig   = {[0.22 0.65 0.95],[0.22 0.88 0.55]};
    colors_noise = {[0.7 0.3 0.3],[0.7 0.5 0.2]};

    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd), continue; end
        [sod, tof, filt] = get_range_data(crd);
        if isempty(sod), continue; end
        c_light = 299792458;
        range_m = tof * c_light / 2;
        idx_sig = filt == 2;
        if ~any(idx_sig), idx_sig = true(size(sod)); end

        if show_raw && ~sig_only
            idx_noise = ~idx_sig;
            if any(idx_noise)
                scatter(ax1, sod(idx_noise), range_m(idx_noise), 2, ...
                    colors_noise{slot},'filled','MarkerFaceAlpha',0.3, ...
                    'DisplayName',sprintf('Noise S%d',slot));
            end
        end
        if sig_only, mask = idx_sig; else, mask = true(size(sod)); end
        scatter(ax1, sod(mask), range_m(mask), 3, colors_sig{slot},'filled', ...
            'MarkerFaceAlpha',0.6, ...
            'DisplayName',sprintf('%s (%d)',get_station_label(crd),sum(mask)));
    end
    legend(ax1,'show','Location','best','TextColor',[0.8 0.85 0.9], ...
        'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax1,'off');

    if ~has_bot, return; end

    pw = (0.88 - 0.04*max(nbot-1,0)) / max(nbot,1);
    x_starts = 0.07 + (0:nbot-1)*(pw+0.04);
    yb = 0.06; hb = 0.38;
    bot_idx = 0;

    if show_resid
        bot_idx = bot_idx + 1;
        ax = uiaxes(panel,'Units','normalized', ...
            'Position',[x_starts(bot_idx) yb pw hb]);
        style_axes(ax); hold(ax,'on');
        for slot = 1:2
            crd = get_crd(app,slot);
            if isempty(crd), continue; end
            [sod, tof, filt] = get_range_data(crd);
            if isempty(sod), continue; end
            idx_sig = filt == 2;
            if ~any(idx_sig), idx_sig = true(size(sod)); end
            resid_ps = compute_residuals_ps(sod(idx_sig), tof(idx_sig));
            scatter(ax, sod(idx_sig), resid_ps, 2, colors_sig{slot},'filled', ...
                'MarkerFaceAlpha',0.5,'DisplayName',get_station_label(crd));
            yline(ax,0,'--','Color',[0.7 0.7 0.7],'LineWidth',1, ...
                'HandleVisibility','off');
            rms_val = sqrt(mean(resid_ps.^2));
            ax.Title.String = sprintf('Residuals S%d  RMS=%.1fps',slot,rms_val);
        end
        ax.XLabel.String = 'Seconds of Day (s)';
        ax.YLabel.String = 'Residual (ps)';
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9], ...
            'Color',[0.15 0.16 0.18],'FontSize',8);
        hold(ax,'off');
    end

    if show_hist
        bot_idx = bot_idx + 1;
        ax = uiaxes(panel,'Units','normalized', ...
            'Position',[x_starts(bot_idx) yb pw hb]);
        style_axes(ax); hold(ax,'on');
        for slot = 1:2
            crd = get_crd(app,slot);
            if isempty(crd), continue; end
            [sod, tof, filt] = get_range_data(crd);
            if isempty(sod), continue; end
            idx_sig = filt == 2;
            if ~any(idx_sig), idx_sig = true(size(sod)); end
            resid_ps = compute_residuals_ps(sod(idx_sig), tof(idx_sig));
            histogram(ax, resid_ps, 60, 'FaceColor',colors_sig{slot}, ...
                'FaceAlpha',0.55,'EdgeColor','none', ...
                'DisplayName',get_station_label(crd));
        end
        ax.XLabel.String = 'Residual (ps)';
        ax.YLabel.String = 'Count';
        ax.Title.String  = 'Residual Histogram';
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9], ...
            'Color',[0.15 0.16 0.18],'FontSize',8);
        hold(ax,'off');
    end

    if show_rate
        bot_idx = bot_idx + 1;
        ax = uiaxes(panel,'Units','normalized', ...
            'Position',[x_starts(bot_idx) yb pw hb]);
        style_axes(ax); hold(ax,'on');
        for slot = 1:2
            crd = get_crd(app,slot);
            if isempty(crd), continue; end
            [sod, ~, filt] = get_range_data(crd);
            if isempty(sod), continue; end
            bin_w  = 10;
            edges  = min(sod):bin_w:max(sod)+bin_w;
            n_tot  = histcounts(sod, edges);
            n_sig  = histcounts(sod(filt==2), edges);
            rate   = 100 * n_sig ./ max(n_tot,1);
            t_bin  = edges(1:end-1) + bin_w/2;
            plot(ax, t_bin, rate, '.-','Color',colors_sig{slot},'LineWidth',1.2, ...
                'MarkerSize',6,'DisplayName',get_station_label(crd));
        end
        ax.XLabel.String = 'Seconds of Day (s)';
        ax.YLabel.String = 'Return Rate (%)';
        ax.Title.String  = 'Return Rate (10-s bins)';
        ylim(ax,[0 100]);
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9], ...
            'Color',[0.15 0.16 0.18],'FontSize',8);
        hold(ax,'off');
    end
end

% =========================================================================
%  TAB: CALIBRATION
% =========================================================================
function fill_tab_calib(fig, tab)
    app = fig.UserData;
    have1 = ~isempty(app.crd1) && ...
            (isfield(app.crd1,'rec40')||isfield(app.crd1,'rec41'));
    have2 = ~isempty(app.crd2) && ...
            (isfield(app.crd2,'rec40')||isfield(app.crd2,'rec41'));
    if ~have1 && ~have2
        no_data_label(tab,'No calibration data (records 40/41) available.'); return;
    end

    g = uigridlayout(tab,[1 2]);
    g.BackgroundColor = [0.13 0.14 0.16];
    g.ColumnWidth = {'1x','1x'};
    g.Padding = [6 6 6 6];

    for slot = 1:2
        crd = get_crd(app,slot);
        p = uipanel(g,'BackgroundColor',[0.15 0.16 0.18],'BorderType','none');
        p.Layout.Column = slot;
        if isempty(crd)
            g2 = uigridlayout(p,[1 1]);
            g2.BackgroundColor = [0.15 0.16 0.18];
            uilabel(g2,'Text','(no file)','FontColor',[0.4 0.5 0.6], ...
                'FontSize',12,'HorizontalAlignment','center', ...
                'VerticalAlignment','center','BackgroundColor',[0.15 0.16 0.18]);
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

    uilabel(pg,'Text',sprintf('File %d - Calibration',slot), ...
        'FontColor',hdrC,'FontWeight','bold','FontSize',13, ...
        'BackgroundColor',[0.15 0.16 0.18]);

    uitextarea(pg,'Value',calib_summary_lines(crd),'Editable','off', ...
        'BackgroundColor',[0.10 0.11 0.13], ...
        'FontColor',[0.82 0.88 0.95],'FontSize',11,'FontName','Courier New');

    ax = uiaxes(pg);
    style_axes(ax);
    plot_calib_history(ax, crd, hdrC);
end

function lines = calib_summary_lines(crd)
    lines = {};
    function addl(s),    lines{end+1} = s; end %#ok
    function addkv(k,v), addl(sprintf('  %-26s %s', k, v)); end %#ok

    recs   = {};
    labels = {};
    if isfield(crd,'rec40')&&~isempty(crd.rec40), recs{end+1}=crd.rec40; labels{end+1}='Pre-pass (40)'; end
    if isfield(crd,'rec41')&&~isempty(crd.rec41), recs{end+1}=crd.rec41; labels{end+1}='Post-pass (41)'; end
    if isfield(crd,'rec42')&&~isempty(crd.rec42), recs{end+1}=crd.rec42; labels{end+1}='In-pass (42)'; end

    for kr = 1:numel(recs)
        addl(sprintf('--- %s (%d records) ---', labels{kr}, height(recs{kr})));
        d = recs{kr};
        for k = 1:height(d)
            row = d(k,:);
            addl(sprintf('  Record #%d', k));
            addkv('  Config ID:',       tbl_str(row.config_id));
            addkv('  Sys delay (ps):',  fmt_na(row.sysdelay_ps));
            addkv('  Delay shift:',     fmt_na(row.sysdelay_shift));
            addkv('  RMS (ps):',        fmt_na(row.rms_ps));
            addkv('  Skew:',            fmt_na(row.skew));
            addkv('  Kurtosis:',        fmt_na(row.kurtosis));
            addkv('  Peak-Mean (ps):',  fmt_na(row.peak_mean_ps));
            addkv('  N firings:',       fmt_na(row.n_firings));
            addkv('  N returns:',       fmt_na(row.n_returns));
            addkv('  Return rate (%):', fmt_na(row.return_rate_pct));
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
        d   = recs{kr};
        sod = d.sod;
        sd  = d.sysdelay_ps;
        rms = d.rms_ps;
        valid = ~isnan(sd);
        if any(valid)
            errorbar(ax, sod(valid), sd(valid), rms(valid), rms(valid), ...
                styles{min(kr,3)}, 'Color',color, ...
                'MarkerFaceColor',color,'MarkerSize',6, ...
                'LineWidth',1.2,'DisplayName',labels{kr},'CapSize',4);
            has_data = true;
        end
    end
    if has_data
        ax.XLabel.String = 'Seconds of Day (s)';
        ax.YLabel.String = 'System Delay (ps)';
        ax.Title.String  = 'Calibration: System Delay +/- RMS';
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9], ...
            'Color',[0.15 0.16 0.18],'FontSize',9);
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
        no_data_label(tab,'No meteorological data (record 20) available.'); return;
    end

    fields_y = {'pressure_mbar','temp_K','humidity_pct'};
    ylabels  = {'Pressure (mbar)','Temperature (K)','Humidity (%)'};
    titles   = {'Atmospheric Pressure','Temperature','Relative Humidity'};
    colors   = {[0.22 0.65 0.95],[0.22 0.88 0.55]};
    ypos     = [0.68, 0.37, 0.06];

    for fi = 1:3
        ax = uiaxes(tab,'Units','normalized','Position',[0.07 ypos(fi) 0.88 0.27]);
        style_axes(ax); hold(ax,'on');
        for slot = 1:2
            crd = get_crd(app,slot);
            if isempty(crd)||~isfield(crd,'rec20')||isempty(crd.rec20), continue; end
            d = crd.rec20;
            y = d.(fields_y{fi});
            valid = ~isnan(y);
            if ~any(valid), continue; end
            plot(ax, d.sod(valid), y(valid), '.-','Color',colors{slot}, ...
                'LineWidth',1.2,'MarkerSize',5,'DisplayName',get_station_label(crd));
        end
        ax.XLabel.String = 'Seconds of Day (s)';
        ax.YLabel.String = ylabels{fi};
        ax.Title.String  = titles{fi};
        legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9], ...
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
        no_data_label(tab,'No pointing data (record 30) available.'); return;
    end

    colors = {[0.22 0.65 0.95],[0.22 0.88 0.55]};
    pos = {[0.06 0.53 0.40 0.43],[0.54 0.53 0.40 0.43], ...
           [0.06 0.05 0.40 0.43],[0.54 0.05 0.40 0.43]};

    ax1 = uiaxes(tab,'Units','normalized','Position',pos{1}); style_axes(ax1); hold(ax1,'on');
    ax2 = uiaxes(tab,'Units','normalized','Position',pos{2}); style_axes(ax2); hold(ax2,'on');
    ax3 = uiaxes(tab,'Units','normalized','Position',pos{3}); style_axes(ax3); hold(ax3,'on');
    ax4 = uiaxes(tab,'Units','normalized','Position',pos{4}); style_axes(ax4); hold(ax4,'on');

    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd)||~isfield(crd,'rec30')||isempty(crd.rec30), continue; end
        d   = crd.rec30;
        lbl = get_station_label(crd);

        plot(ax1,d.sod,d.azimuth,'.-','Color',colors{slot}, ...
            'LineWidth',1,'MarkerSize',4,'DisplayName',lbl);
        plot(ax2,d.sod,d.elevation,'.-','Color',colors{slot}, ...
            'LineWidth',1,'MarkerSize',4,'DisplayName',lbl);

        az_rad = d.azimuth * pi/180;
        r_sky  = 90 - d.elevation;
        [xp,yp] = deal(r_sky.*sin(az_rad), r_sky.*cos(az_rad));
        scatter(ax3,xp,yp,5,colors{slot},'filled','DisplayName',lbl);

        [sod_r,tof,~] = get_range_data(crd);
        if ~isempty(sod_r)
            el_i = interp1(d.sod, d.elevation, sod_r, 'linear','extrap');
            range_km = tof * 299792458 / 2 / 1000;
            scatter(ax4,range_km,el_i,2,colors{slot},'filled', ...
                'MarkerFaceAlpha',0.4,'DisplayName',lbl);
        end
    end

    % Sky plot: elevation rings
    for el_ring = [30 60]
        theta  = linspace(0,2*pi,361);
        r_ring = 90 - el_ring;
        plot(ax3, r_ring*sin(theta), r_ring*cos(theta), '--', ...
            'Color',[0.4 0.5 0.6],'LineWidth',0.7,'HandleVisibility','off');
        text(ax3,0,r_ring+2,sprintf('%d deg',el_ring),'Color',[0.6 0.7 0.8], ...
            'FontSize',8,'HorizontalAlignment','center');
    end

    ax1.XLabel.String='Seconds of Day (s)'; ax1.YLabel.String='Azimuth (deg)';
    ax1.Title.String='Azimuth vs Time';
    legend(ax1,'show','Location','best','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax1,'off');

    ax2.XLabel.String='Seconds of Day (s)'; ax2.YLabel.String='Elevation (deg)';
    ax2.Title.String='Elevation vs Time';
    legend(ax2,'show','Location','best','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax2,'off');

    axis(ax3,'equal');
    ax3.XAxis.Visible='off'; ax3.YAxis.Visible='off';
    ax3.Title.String='Sky Plot (N up)';
    legend(ax3,'show','Location','southoutside','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax3,'off');

    ax4.XLabel.String='Range (km)'; ax4.YLabel.String='Elevation (deg)';
    ax4.Title.String='Elevation vs Range';
    legend(ax4,'show','Location','best','TextColor',[0.8 0.85 0.9],'Color',[0.15 0.16 0.18],'FontSize',9);
    hold(ax4,'off');
end

% =========================================================================
%  TAB: STATISTICS
% =========================================================================
function fill_tab_stats(fig, tab)
    app = fig.UserData;
    if isempty(app.crd1) && isempty(app.crd2)
        no_data_label(tab,'No data loaded.'); return;
    end

    g = uigridlayout(tab,[2 2]);
    g.BackgroundColor = [0.13 0.14 0.16];
    g.RowHeight   = {'1x','1x'};
    g.ColumnWidth = {'1x','1x'};
    g.Padding = [6 6 6 6];

    colors = {[0.22 0.55 0.80],[0.22 0.70 0.45]};

    for slot = 1:2
        crd = get_crd(app,slot);
        p = uipanel(g,'BackgroundColor',[0.15 0.16 0.18],'BorderType','none');
        p.Layout.Row = 1; p.Layout.Column = slot;
        pg = uigridlayout(p,[2 1]);
        pg.RowHeight = {24,'1x'};
        pg.BackgroundColor = [0.15 0.16 0.18];
        pg.Padding = [4 4 4 4];
        uilabel(pg,'Text',sprintf('File %d - Statistics',slot), ...
            'FontColor',colors{slot},'FontWeight','bold','FontSize',13, ...
            'BackgroundColor',[0.15 0.16 0.18]);
        if ~isempty(crd), lines = compute_stats_lines(crd);
        else,              lines = {'(no file loaded)'}; end
        uitextarea(pg,'Value',lines,'Editable','off', ...
            'BackgroundColor',[0.10 0.11 0.13], ...
            'FontColor',[0.82 0.88 0.95],'FontSize',11,'FontName','Courier New');
    end

    p_bar = uipanel(g,'BackgroundColor',[0.15 0.16 0.18],'BorderType','none');
    p_bar.Layout.Row = 2; p_bar.Layout.Column = [1 2];
    ax = uiaxes(p_bar,'Units','normalized','Position',[0.06 0.1 0.88 0.85]);
    style_axes(ax);
    build_comparison_chart(ax, app, colors);
end

function lines = compute_stats_lines(crd)
    lines = {};
    function addl(s),    lines{end+1} = s; end %#ok
    function addkv(k,v), addl(sprintf('  %-28s %s', k, v)); end %#ok

    addl('--- RANGE DATA STATISTICS ---');
    [sod, tof, filt] = get_range_data(crd);
    if ~isempty(sod)
        c_light  = 299792458;
        range_m  = tof * c_light / 2;
        idx_sig  = filt == 2;
        if ~any(idx_sig), idx_sig = true(size(sod)); end
        resid_ps = compute_residuals_ps(sod(idx_sig), tof(idx_sig));

        addkv('Total records:',     num2str(numel(sod)));
        addkv('Signal records:',    num2str(sum(idx_sig)));
        addkv('Noise records:',     num2str(sum(~idx_sig)));
        addkv('Return rate (%):',   sprintf('%.2f', 100*sum(idx_sig)/numel(sod)));
        addkv('Min range (m):',     sprintf('%.3f', min(range_m(idx_sig))));
        addkv('Max range (m):',     sprintf('%.3f', max(range_m(idx_sig))));
        addkv('Mean range (m):',    sprintf('%.3f', mean(range_m(idx_sig))));
        addkv('Pass duration (s):', sprintf('%.1f', max(sod)-min(sod)));
        addl('');
        addl('--- RESIDUAL STATISTICS ---');
        addkv('RMS (ps):',          sprintf('%.2f', sqrt(mean(resid_ps.^2))));
        addkv('Mean (ps):',         sprintf('%.2f', mean(resid_ps)));
        addkv('Std dev (ps):',      sprintf('%.2f', std(resid_ps)));
        addkv('Skewness:',          sprintf('%.4f', skewness(resid_ps)));
        addkv('Kurtosis:',          sprintf('%.4f', kurtosis(resid_ps)));
        addkv('Peak-Peak (ps):',    sprintf('%.2f', max(resid_ps)-min(resid_ps)));
    else
        addl('  No range data available.');
    end

    addl('');
    addl('--- SESSION STATS (Record 50) ---');
    if isfield(crd,'rec50') && ~isempty(crd.rec50)
        s = crd.rec50(1,:);
        addkv('Config ID:',      tbl_str(s.config_id));
        addkv('RMS (ps):',       fmt_na(s.rms_ps));
        addkv('Skew:',           fmt_na(s.skew));
        addkv('Kurtosis:',       fmt_na(s.kurtosis));
        addkv('Peak-Mean (ps):', fmt_na(s.peak_mean_ps));
    else
        addl('  No record 50 found.');
    end
end

function build_comparison_chart(ax, app, colors)
    metrics = {'RMS (ps)','Skew','Kurtosis','P-P (ps)','Ret.Rate (%)'};
    vals = nan(2, numel(metrics));

    for slot = 1:2
        crd = get_crd(app,slot);
        if isempty(crd), continue; end
        [sod, tof, filt] = get_range_data(crd);
        if ~isempty(sod)
            idx_sig = filt == 2;
            if ~any(idx_sig), idx_sig = true(size(sod)); end
            rp = compute_residuals_ps(sod(idx_sig), tof(idx_sig));
            vals(slot,1) = sqrt(mean(rp.^2));
            vals(slot,2) = skewness(rp);
            vals(slot,3) = kurtosis(rp);
            vals(slot,4) = max(rp)-min(rp);
            vals(slot,5) = 100*sum(idx_sig)/numel(sod);
        end
        if isfield(crd,'rec50') && ~isempty(crd.rec50)
            s = crd.rec50(1,:);
            if ~isnan(s.rms_ps),       vals(slot,1) = s.rms_ps; end
            if ~isnan(s.skew),         vals(slot,2) = s.skew; end
            if ~isnan(s.kurtosis),     vals(slot,3) = s.kurtosis; end
            if ~isnan(s.peak_mean_ps), vals(slot,4) = s.peak_mean_ps; end
        end
    end

    hold(ax,'on');
    x = 1:numel(metrics);
    bw = 0.35;
    for slot = 1:2
        xp = x + (slot-1)*bw - bw/2;
        bar(ax, xp, vals(slot,:), bw, 'FaceColor',colors{slot}, ...
            'EdgeColor','none','FaceAlpha',0.8, ...
            'DisplayName',sprintf('File %d',slot));
        for xi = 1:numel(xp)
            if ~isnan(vals(slot,xi))
                text(ax, xp(xi), vals(slot,xi)*1.02, sprintf('%.1f',vals(slot,xi)), ...
                    'HorizontalAlignment','center','Color',colors{slot},'FontSize',8);
            end
        end
    end
    ax.XTick = x;
    ax.XTickLabel = metrics;
    ax.XTickLabelRotation = 10;
    ax.YLabel.String = 'Value';
    ax.Title.String  = 'Key Metrics: File 1 vs File 2';
    legend(ax,'show','Location','best','TextColor',[0.8 0.85 0.9], ...
        'Color',[0.15 0.16 0.18],'FontSize',10);
    hold(ax,'off');
end

% =========================================================================
%  CRD v2 PARSER
% =========================================================================
function crd = parse_crd_v2(filename)
% Parse an ILRS CRD v2 file. Returns a struct with fields for each record type.

    crd = struct();
    crd.filename = filename;

    fid = fopen(filename,'r');
    if fid == -1, error('Cannot open file: %s', filename); end
    raw_lines = {};
    while ~feof(fid)
        raw_lines{end+1} = fgetl(fid); %#ok
    end
    fclose(fid);

    r10=[]; r11=[]; r12=[];
    r20=[]; r30=[];
    r40=[]; r41=[]; r42=[];
    r50=[];
    comments={};
    C0_list={}; C1_list={}; C2_list={}; C3_list={};
    C5_list={}; C6_list={}; C7_list={};

    for li = 1:numel(raw_lines)
        line = strtrim(raw_lines{li});
        if isempty(line) || ~ischar(line), continue; end

        tok   = strsplit(line);
        recid = lower(tok{1});

        switch recid
            case 'h1', crd.H1 = parse_H1(tok);
            case 'h2', crd.H2 = parse_H2(tok);
            case 'h3', crd.H3 = parse_H3(tok);
            case 'h4', crd.H4 = parse_H4(tok);
            case 'h5', crd.H5 = parse_H5(tok);
            case 'h8', crd.H8.raw = strjoin(tok(2:end),' ');
            case 'h9', % session end
            case 'c0', C0_list{end+1} = parse_C0(tok); %#ok
            case 'c1', C1_list{end+1} = parse_C1(tok); %#ok
            case 'c2', C2_list{end+1} = parse_C2(tok); %#ok
            case 'c3', C3_list{end+1} = parse_C3(tok); %#ok
            case 'c5', C5_list{end+1} = parse_C5(tok); %#ok
            case 'c6', C6_list{end+1} = parse_C6(tok); %#ok
            case 'c7', C7_list{end+1} = struct('raw',strjoin(tok(2:end),' ')); %#ok
            case '10', r10 = [r10; parse_rec10(tok)]; %#ok
            case '11', r11 = [r11; parse_rec11(tok)]; %#ok
            case '12', r12 = [r12; parse_rec12(tok)]; %#ok
            case '20', r20 = [r20; parse_rec20(tok)]; %#ok
            case '30', r30 = [r30; parse_rec30(tok)]; %#ok
            case '40', r40 = [r40; parse_rec40(tok)]; %#ok
            case '41', r41 = [r41; parse_rec41(tok)]; %#ok
            case '42', r42 = [r42; parse_rec42(tok)]; %#ok
            case '50', r50 = [r50; parse_rec50(tok)]; %#ok
            case '00', comments{end+1} = strjoin(tok(2:end),' '); %#ok
        end
    end

    if ~isempty(C0_list), crd.C0 = vstruct(C0_list); end
    if ~isempty(C1_list), crd.C1 = vstruct(C1_list); end
    if ~isempty(C2_list), crd.C2 = vstruct(C2_list); end
    if ~isempty(C3_list), crd.C3 = vstruct(C3_list); end
    if ~isempty(C5_list), crd.C5 = vstruct(C5_list); end
    if ~isempty(C6_list), crd.C6 = vstruct(C6_list); end
    if ~isempty(C7_list), crd.C7 = vstruct(C7_list); end

    if ~isempty(r10), crd.rec10 = sarr2tbl(r10); end
    if ~isempty(r11), crd.rec11 = sarr2tbl(r11); end
    if ~isempty(r12), crd.rec12 = sarr2tbl(r12); end
    if ~isempty(r20), crd.rec20 = sarr2tbl(r20); end
    if ~isempty(r30), crd.rec30 = sarr2tbl(r30); end
    if ~isempty(r40), crd.rec40 = sarr2tbl(r40); end
    if ~isempty(r41), crd.rec41 = sarr2tbl(r41); end
    if ~isempty(r42), crd.rec42 = sarr2tbl(r42); end
    if ~isempty(r50), crd.rec50 = sarr2tbl(r50); end
    crd.comments = comments;
end

% --- Header parsers ---
function s = parse_H1(tok)
    s.record_type = 'H1';
    s.crd_version = gn(tok,3,2);
    s.year        = gn(tok,4,0);
    s.month       = gn(tok,5,0);
    s.day         = gn(tok,6,0);
    s.hour        = gn(tok,7,0);
end

function s = parse_H2(tok)
    s.record_type  = 'H2';
    s.station_name = gs(tok,2,'unknown');
    s.cdp_pad_id   = gs(tok,3,'0000');
    s.cdp_sys_num  = gn(tok,4,0);
    s.cdp_occ_num  = gn(tok,5,0);
    s.timescale    = gn(tok,6,0);
    s.network      = gs(tok,7,'ILRS');
end

function s = parse_H3(tok)
    s.record_type = 'H3';
    s.target_name = gs(tok,2,'unknown');
    s.ilrs_id     = gs(tok,3,'0');
    s.sic         = gs(tok,4,'0');
    s.norad       = gs(tok,5,'0');
    s.sc_flag     = gn(tok,6,0);
    s.srp_flag    = gn(tok,7,0);
    s.reflectivity= gn(tok,8,0);
end

function s = parse_H4(tok)
    s.record_type      = 'H4';
    s.data_type        = gn(tok,2,0);
    s.start_year       = gn(tok,3,0);
    s.start_month      = gn(tok,4,0);
    s.start_day        = gn(tok,5,0);
    s.start_hour       = gn(tok,6,0);
    s.start_min        = gn(tok,7,0);
    s.start_sec        = gn(tok,8,0);
    s.end_year         = gn(tok,9,0);
    s.end_month        = gn(tok,10,0);
    s.end_day          = gn(tok,11,0);
    s.end_hour         = gn(tok,12,0);
    s.end_min          = gn(tok,13,0);
    s.end_sec          = gn(tok,14,0);
    s.sysdelay_applied = gn(tok,15,0);
    s.tropo_applied    = gn(tok,16,0);
    s.com_applied      = gn(tok,17,0);
    s.xcm_applied      = gn(tok,18,0);
    s.data_release     = gn(tok,19,0);
    s.ranging_mode     = gn(tok,21,0);
end

function s = parse_H5(tok)
    s.record_type    = 'H5';
    s.pred_type      = gn(tok,2,0);
    s.pred_file_name = gs(tok,3,'na');
    s.pred_pnt_epoch = gn(tok,4,NaN);
    s.pred_interval  = gn(tok,5,NaN);
end

% --- Config parsers ---
function s = parse_C0(tok)
    s.record_type   = 'C0';
    s.detail_type   = gn(tok,2,0);
    s.wavelength_nm = gn(tok,3,NaN);
    s.config_id     = gs(tok,4,'na');
    s.laser_id      = gs(tok,5,'na');
    s.detector_id   = gs(tok,6,'na');
    s.timer_id      = gs(tok,7,'na');
    s.meteo_id      = gs(tok,8,'na');
    s.cal_id        = gs(tok,9,'na');
end

function s = parse_C1(tok)
    s.record_type     = 'C1';
    s.detail_type     = gn(tok,2,0);
    s.laser_id        = gs(tok,3,'na');
    s.laser_type      = gs(tok,4,'na');
    s.wavelength_nm   = gn(tok,5,NaN);
    s.nom_fire_rate   = gn(tok,6,NaN);
    s.pulse_energy_mJ = gn(tok,7,NaN);
    s.pulse_width_ps  = gn(tok,8,NaN);
    s.beam_div_urad   = gn(tok,9,NaN);
    s.pulses_semitrain= gn(tok,10,NaN);
end

function s = parse_C2(tok)
    s.record_type         = 'C2';
    s.detail_type         = gn(tok,2,0);
    s.detector_id         = gs(tok,3,'na');
    s.detector_type       = gs(tok,4,'na');
    s.wavelength_nm       = gn(tok,5,NaN);
    s.qe_pct              = gn(tok,6,NaN);
    s.voltage_V           = gn(tok,7,NaN);
    s.dark_count_kHz      = gn(tok,8,NaN);
    s.output_pulse_type   = gs(tok,9,'na');
    s.output_pulse_width  = gn(tok,10,NaN);
    s.spectral_filter_nm  = gn(tok,11,NaN);
    s.spectral_fwhm_nm    = gn(tok,12,NaN);
    s.spatial_filter      = gn(tok,13,NaN);
    s.ext_signal_proc     = gs(tok,14,'na');
    s.amp_in_ps           = gn(tok,15,NaN);
    s.amp_out_ps          = gn(tok,16,NaN);
end

function s = parse_C3(tok)
    s.record_type        = 'C3';
    s.detail_type        = gn(tok,2,0);
    s.timer_id           = gs(tok,3,'na');
    s.timer_name         = gs(tok,4,'na');
    s.freq_MHz           = gn(tok,5,NaN);
    s.time_resolution_ps = gn(tok,6,NaN);
    s.accuracy_corr      = gn(tok,7,NaN);
end

function s = parse_C5(tok)
    s.record_type  = 'C5';
    s.detail_type  = gn(tok,2,0);
    s.meteo_id     = gs(tok,3,'na');
    s.pres_uncert  = gn(tok,4,NaN);
    s.temp_uncert  = gn(tok,5,NaN);
    s.humid_uncert = gn(tok,6,NaN);
end

function s = parse_C6(tok)
    s.record_type = 'C6';
    s.detail_type = gn(tok,2,0);
    s.cal_id      = gs(tok,3,'na');
    s.range_m     = gn(tok,4,NaN);
end

% --- Data record parsers ---
function s = parse_rec10(tok)
    s.sod         = gn(tok,2,NaN);
    s.tof         = gn(tok,3,NaN);
    s.config_id   = gs(tok,4,'na');
    s.epoch_event = gn(tok,5,0);
    s.filter_flag = gn(tok,6,0);
    s.detector_ch = gn(tok,7,NaN);
    s.stop_num    = gn(tok,8,NaN);
    s.rx_amp      = gn(tok,9,NaN);
    s.tx_amp      = gn(tok,10,NaN);
end

function s = parse_rec11(tok)
    s.sod             = gn(tok,2,NaN);
    s.tof             = gn(tok,3,NaN);
    s.config_id       = gs(tok,4,'na');
    s.epoch_event     = gn(tok,5,0);
    s.np_window_s     = gn(tok,6,NaN);
    s.n_raw           = gn(tok,7,NaN);
    s.bin_rms_ps      = gn(tok,8,NaN);
    s.skew            = gn(tok,9,NaN);
    s.kurtosis        = gn(tok,10,NaN);
    s.peak_mean_ps    = gn(tok,11,NaN);
    s.return_rate_pct = gn(tok,12,NaN);
    s.detector_ch     = gn(tok,13,NaN);
    s.snr             = gn(tok,14,NaN);
    s.filter_flag     = 2;
end

function s = parse_rec12(tok)
    s = parse_rec10(tok);
    s.np_window_s     = gn(tok,11,NaN);
    s.n_raw           = gn(tok,12,NaN);
    s.bin_rms_ps      = gn(tok,13,NaN);
    s.return_rate_pct = gn(tok,14,NaN);
end

function s = parse_rec20(tok)
    s.sod           = gn(tok,2,NaN);
    s.pressure_mbar = gn(tok,3,NaN);
    s.temp_K        = gn(tok,4,NaN);
    s.humidity_pct  = gn(tok,5,NaN);
    s.origin_flag   = gn(tok,6,NaN);
end

function s = parse_rec30(tok)
    s.sod            = gn(tok,2,NaN);
    s.azimuth        = gn(tok,3,NaN);
    s.elevation      = gn(tok,4,NaN);
    s.direction_flag = gn(tok,5,NaN);
    s.origin_flag    = gn(tok,6,NaN);
    s.az_rate        = gn(tok,7,NaN);
    s.el_rate        = gn(tok,8,NaN);
end

function s = parse_rec40(tok), s = calib_common(tok); s.type=40; end
function s = parse_rec41(tok), s = calib_common(tok); s.type=41; end
function s = parse_rec42(tok), s = calib_common(tok); s.type=42; end

function s = calib_common(tok)
    s.sod              = gn(tok,2,NaN);
    s.type_flag        = gn(tok,3,0);
    s.config_id        = gs(tok,4,'na');
    s.n_firings        = gn(tok,5,NaN);
    s.n_returns        = gn(tok,6,NaN);
    s.return_rate_pct  = gn(tok,7,NaN);
    s.sysdelay_ps      = gn(tok,8,NaN);
    s.sysdelay_shift   = gn(tok,9,NaN);
    s.rms_ps           = gn(tok,10,NaN);
    s.skew             = gn(tok,11,NaN);
    s.kurtosis         = gn(tok,12,NaN);
    s.peak_mean_ps     = gn(tok,13,NaN);
    s.cal_type_flag    = gn(tok,14,NaN);
    s.cal_shift_flag   = gn(tok,15,NaN);
    s.noise_flag       = gn(tok,16,NaN);
    s.window_flag      = gn(tok,17,NaN);
    s.ret_rate_flag    = gn(tok,18,NaN);
end

function s = parse_rec50(tok)
    s.config_id      = gs(tok,2,'na');
    s.rms_ps         = gn(tok,3,NaN);
    s.skew           = gn(tok,4,NaN);
    s.kurtosis       = gn(tok,5,NaN);
    s.peak_mean_ps   = gn(tok,6,NaN);
    s.data_qual_flag = gn(tok,7,NaN);
end

% --- Token helpers ---
function v = gn(tok, idx, default)
    if idx > numel(tok), v = default; return; end
    t = lower(strtrim(tok{idx}));
    if any(strcmp(t,{'na','n/a',''})), v = NaN; return; end
    v = str2double(t);
    if isnan(v), v = default; end
end

function v = gs(tok, idx, default)
    if idx > numel(tok), v = default; return; end
    v = strtrim(tok{idx});
    if isempty(v), v = default; end
end

% --- Struct/table helpers ---
function out = vstruct(list)
    out = list{1};
    for k = 2:numel(list)
        out(end+1) = list{k}; %#ok
    end
end

function T = sarr2tbl(sarr)
    try
        T = struct2table(sarr);
    catch
        T = table();
        fns = fieldnames(sarr);
        for k = 1:numel(fns)
            fn  = fns{k};
            raw = {sarr.(fn)};
            try
                T.(fn) = cell2mat(raw)';
            catch
                T.(fn) = raw';
            end
        end
    end
end

% =========================================================================
%  UTILITY FUNCTIONS
% =========================================================================
function [sod, tof, filt] = get_range_data(crd)
    sod=[]; tof=[]; filt=[];
    if isfield(crd,'rec10') && ~isempty(crd.rec10)
        sod  = crd.rec10.sod;
        tof  = crd.rec10.tof;
        filt = crd.rec10.filter_flag;
    elseif isfield(crd,'rec11') && ~isempty(crd.rec11)
        sod  = crd.rec11.sod;
        tof  = crd.rec11.tof;
        filt = 2*ones(size(sod));
    elseif isfield(crd,'rec12') && ~isempty(crd.rec12)
        sod  = crd.rec12.sod;
        tof  = crd.rec12.tof;
        filt = crd.rec12.filter_flag;
    end
    if ~isempty(sod)
        ok   = ~isnan(sod) & ~isnan(tof);
        sod  = sod(ok);  tof  = tof(ok);  filt = filt(ok);
    end
end

function resid_ps = compute_residuals_ps(sod, tof)
    % Polynomial fit to TOF(t); residuals in picoseconds (2-way)
    if numel(sod) < 4
        resid_ps = zeros(size(sod)); return;
    end
    sod_n  = (sod - mean(sod)) / max(std(sod),1);
    deg    = max(2, min(6, floor(numel(sod)/10)));
    p      = polyfit(sod_n, tof, deg);
    resid_ps = (tof - polyval(p, sod_n)) * 1e12;   % seconds -> picoseconds
end

function label = get_station_label(crd)
    if isfield(crd,'H2')
        label = sprintf('%s/%s', crd.H2.station_name, crd.H2.cdp_pad_id);
    else
        label = 'Unknown';
    end
end

function crd = get_crd(app, slot)
    if slot==1, crd=app.crd1; else, crd=app.crd2; end
end

function s = fmt_na(v)
    v = v(1);   % ensure scalar from table indexing
    if isnan(v), s='na'; else, s=sprintf('%.5g',v); end
end

function v = tbl_str(x)
    if iscell(x), x=x{1}; end
    v = char(x);
end

function no_data_label(parent, msg)
    g = uigridlayout(parent,[1 1]);
    g.BackgroundColor = [0.13 0.14 0.16];
    uilabel(g,'Text',msg,'FontColor',[0.5 0.6 0.7],'FontSize',13, ...
        'HorizontalAlignment','center','VerticalAlignment','center', ...
        'BackgroundColor',[0.13 0.14 0.16]);
end

function style_axes(ax)
    ax.Color          = [0.10 0.11 0.13];
    ax.XColor         = [0.65 0.72 0.80];
    ax.YColor         = [0.65 0.72 0.80];
    ax.GridColor      = [0.25 0.28 0.32];
    ax.MinorGridColor = [0.18 0.20 0.23];
    ax.GridAlpha      = 0.4;
    ax.XGrid          = 'on';
    ax.YGrid          = 'on';
    ax.Box            = 'on';
    ax.Title.Color    = [0.85 0.90 0.95];
    ax.Title.FontSize = 11;
    ax.XLabel.Color   = [0.70 0.78 0.88];
    ax.YLabel.Color   = [0.70 0.78 0.88];
    ax.FontSize       = 10;
    ax.TickDir        = 'out';
end
