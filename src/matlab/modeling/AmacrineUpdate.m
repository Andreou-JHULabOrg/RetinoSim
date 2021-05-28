function [ threshold_on_update, threshold_off_update, loss_on, loss_off ] = AmacrineUpdate(...
    learning_rate, ...
    epc, ...
    isi, ...
    ideal, ...
    update_mode, ...
    model_params, ...
    intensity_params, ...
    nframes)
%AmacrineUpdate 

% dL.on = (2*(ideal.on - epc.on));
% dL.off = (2*(ideal.off - epc.off));

% dL.on = (2*epc.on.*(ideal.on - epc.on));
% dL.off = (2*epc.off.*(ideal.off - epc.off));

dt = (1/model_params.frames_per_second);
alpha_E = log(intensity_params.end_level)-log(intensity_params.starting_level);
alpha_T = dt*size(nframes,3)/(intensity_params.iterations*alpha_E);

if strcmp(update_mode, 'epc')% epc dL
    dL.on = alpha_E*(2*(ideal.on - epc.on))./abs(model_params.on_threshold).^2;
    dL.off = alpha_E*(2*(ideal.off - epc.off))./abs(model_params.off_threshold).^2;
else % isi dL
    dL.on = (2*(ideal.on - epc.on))*alpha_T;
    dL.off = (2*(ideal.off - epc.off))*alpha_T;
end

threshold_on_update = model_params.on_threshold - learning_rate.on*dL.on;
threshold_off_update = model_params.off_threshold - learning_rate.off*dL.off;


if strcmp(update_mode, 'epc')
    loss_on = mean(mean((epc.on-ideal.on)));
    loss_off = mean(mean((epc.off-ideal.off)));
else
    loss_on = mean(mean((isi.on-ideal.on)));
    loss_off = mean(mean((isi.off-ideal.off)));
end

end

