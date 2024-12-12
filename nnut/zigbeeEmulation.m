% Generate WiFi payload that emulates dual-band ZigBee
% The ZigBee channel is +- 5MHz w.r.t the center frequency of WiFi
clear;clc;
rng(11);
ht = wlanHTConfig('MCS',7);
ht.ChannelCoding = 'LDPC';
ht.PSDULength = 12000;

%% OFDM emulation and reverse LDPC coding
zigbee_payload = [18 52 86 120 154 188 222 15 18 52 86 120 154 188 222 15];
[matrices,qamSymbZig_ch2,cfg,txPSDU,scrambleInit,symbol_zigbee,zigbee_waveform_20MHz,zigbee_waveform_20MHz_pad,zigbee_waveform_reshaped,zigbee_waveform_fft,fc_quantized,qamSymbZig_ch1] = genZigHTPayload(ht,zigbee_payload);

%% replace the last four bytes with correct FCS
fcsGen = comm.CRCGenerator([32 26 23 22 16 12 11 10 8 7 5 4 2 1 0], ...
    'InitialConditions', 1, ...
    'DirectMethod', true, ...
    'FinalXOR', 1);
bits = step(fcsGen,txPSDU(1:end-32));
txPSDU = bits;

%% test
waveform = wlanHTData(txPSDU,ht,scrambleInit);
writeWiFiSignalTofile(waveform,'CTC_iq.dat',1);

%% print to file
txPSDUtoFile(txPSDU,"payload_2417_2427");
