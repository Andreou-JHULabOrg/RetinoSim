function plotRetinoOutput(dbgFrames,eventFrames, params)
%PLOTRRETINOOUTPUT display frames from event simulator
close all

switch (params.dbg_mode)
    case('opl_str')
        dbg_title_str = 'OPL ST Response';
    case('opl_sr')
        dbg_title_str = 'OPL Spat. Response';
    case('on_neuron')
        dbg_title_str = 'On Neuron Membrane';
    case('off_neuron')
        dbg_title_str = 'Off Neuron Membrane';
    case('photo') 
        dbg_title_str = 'Photoreceptor Input';
end
fig = figure();

fig.Units = 'normalize';
fig.Position=[0.1 0.25 0.8 0.75];

ax(1)=axes;
ax(2)=axes;

x0=0.15;
y0=0.3;
dx=0.25;
dy=0.45;
ax(1).Position=[x0 y0 dx dy];
x0 = x0 + dx + 0.2;
ax(2).Position=[x0 y0 dx dy];

im(1) = imagesc(ax(1),dbgFrames(:,:,1));
ax(1).Title.String = ['Debug - ' dbg_title_str ': Frame ' num2str(1)];
set(ax(1), 'xtick', [], 'ytick', []);
colormap();

im(2) = imagesc(ax(2),eventFrames(:,:,:,1));
ax(2).Title.String = ['Accumulated Events: Frame ' num2str(1)];
set(ax(2), 'xtick', [], 'ytick', []);

for ii = 2:size(dbgFrames,3)
    ax(1).Title.String = ['Debug - ' dbg_title_str ': Frame ' num2str(ii)];
    ax(2).Title.String = ['Accumulated Events: Frame ' num2str(ii)];
    set(im(1),'cdata',dbgFrames(:,:,ii));
    set(im(2),'cdata',eventFrames(:,:,:,ii));
    frame = getframe();
    colorbar(ax(1));
    
    pause(1/60);
end

end

