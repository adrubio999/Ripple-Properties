function properties = compute_ripple_properties(LFP, events, chpyr, fs)

    % Make ripple matrix
    n_events = size(events,1);

    % Initialize
    properties = nan(n_events, 6);
    lfps = cell(n_events,1);

    for irip = 1:n_events
        
        interval = round(events(irip,:) * fs);
        if interval(1)<1, interval(1) = 1; end
        if interval(end)>size(LFP,1), interval(end) = size(LFP,1); end
%         lfp = LFP(interval(1):interval(2), chpyr);
        win = round(mean(events(irip,:))*fs + [-0.05*fs : 0.05*fs]);
        if win(1) < 1
            lfp = zeros(1,length(win));
            win(win<1) = [];
            lfp(1:length(win)) = LFP(win, chpyr);
        elseif win(end) > size(LFP,1)
            win(win>size(LFP,1)) = [];
            lfp(1:length(win)) = LFP(win, chpyr);
        else
            lfp = LFP(win, chpyr);
        end
        
        % Duration
        rip_dur = length(lfp)/fs;
        
        % Frequency and power
        %[rip_freq, rip_power] = LCN_compute_ripple_frequency(lfp, [1 length(lfp)], fs);
        [pS, freq] = power_spectrum(reshape(lfp,1,[]), true, fs, [70,400]);
        [rip_power, imax] = max(pS(2:end));
        rip_freq = freq(1+imax);
        if rip_freq < 90
            modelfun = @(b,x) b(1) * exp(-b(2)*x);
            mdl = fitnlm(table(freq', pS), modelfun, [mean(pS(1:3)) 0.01]);
            bs = mdl.Coefficients{:,'Estimate'};
            pSn = pS - modelfun(bs, freq)';
            [rip_power, imax] = max(pSn(2:end));
            rip_freq = freq(1+imax);
        end
        
        % Spectral characterization
        event = reshape(lfp,1,[]);
        nZeros = round((fs*(200/1000) - length(event))/2);
        event = [zeros(1, nZeros) event zeros(1, nZeros)];
        [pS, freqs] = power_spectrum( event, true, fs, [10,500] );
        
        pSnorm = pS' / sum(pS);
        if length(pSnorm) > length(freqs)
            pSnorm = pSnorm(1:length(freqs));
        elseif length(pSnorm) < length(freqs)
            freqs = freqs(1:length(pSnorm));
        end
        pSnorm(freqs<70) = [];
        freqs(freqs<70) = [];
        
        % Fast, slow ripple index
        rip_fri = sum(pSnorm(freqs > 250));
        rip_sri = sum(pSnorm(freqs < 100));

        % Entropy
        rip_entropy = - sum(pSnorm .* log2(pSnorm) );        
        
        % Save
        properties(irip, :) = [rip_freq rip_power rip_dur rip_fri rip_sri rip_entropy];
        lfps{irip} = lfp;
        
    end
    
    properties = array2table(properties, 'VariableNames', {'frequency', 'power', 'duration', 'FRI', 'SRI', 'entropy'});
    properties = [properties, table(lfps, 'VariableNames', {'waveform'})];

end