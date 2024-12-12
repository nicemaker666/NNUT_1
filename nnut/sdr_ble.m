%% Transmit BLE and XFi (WiFi) in the same WARP device. 
%  This is ideal case for XFi with perfect time synchronization and power
%  control. So this code server serve as the proof-of-concept that XFi
%  works.

clear;
%% generate WiFi signal (subcarrier 13 to 24 is for ZigBee)
ht = wlanHTConfig('MCS',7);
ht.ChannelCoding = 'LDPC';
ht.PSDULength = 12000;
ht.GuardInterval = 'Short';
load('txPSDU_12000.mat');

lstf = wlanLSTF(ht);
lltf = wlanLLTF(ht);
lsig = wlanLSIG(ht);
htsig = wlanHTSIG(ht);
htstf = wlanHTSTF(ht);
htltf = wlanHTLTF(ht);
scrambleInit = [1 ;0; 0; 0; 1; 1; 1];
htData = wlanHTData(txPSDU,ht,scrambleInit);

txPPDU = [lstf; lltf; lsig; htsig; htstf; htltf; htData];
txPPDU = txPPDU / max([real(txPPDU); imag(txPPDU)]); 

%% substitute with ble signal
payload =  '00010203040506070809';
ble_waveform_4MHz = generateBLEwaveform(payload); %baseband signal in 4MHz
ble_waveform_4MHz = ble_waveform_4MHz(12:end);
ble_waveform_2MHz = resample(ble_waveform_4MHz,1,2);
%[bits,decoded_bytes] = decodeGFSK(ble_waveform_2MHz);


ble_waveform_20MHz = resample(ble_waveform_4MHz,5,1);
ble_waveform_20MHz = ble_waveform_20MHz * sqrt(mean(abs(txPPDU).^2)/10) / sqrt(mean(abs(ble_waveform_20MHz).^2)) ;
 
%padding_front = zeros(length([lstf; lltf; lsig; htsig; htstf; htltf]),1);
%padding_end   = zeros(length(htData)-length(ble_waveform_20MHz),1);
delayus = 0;
padding_front = zeros(20*delayus + length([lstf; lltf; lsig; htsig; htstf; htltf]),1);
padding_end  = zeros(length(htData)-length(ble_waveform_20MHz)-20*delayus,1);

carrier_1 =  exp(-1i*2*pi*(33-20)/64*(1:length(txPPDU)));
%carrier_1 =  exp(-1i*2*pi/5*(1:length(txPPDU)));
carrier_2 =  exp(1i*2*pi*(46-33)/64*(1:length(txPPDU)));

zigbee_waveform_1 = [padding_front; ble_waveform_20MHz.' ;padding_end] .* carrier_1.';
zigbee_waveform_2 = [padding_front; ble_waveform_20MHz.' ;padding_end] .* carrier_2.';
zigbee_waveform_3 = [padding_front; ble_waveform_20MHz.' ;padding_end];

wifi_waveform_40MHz = resample(txPPDU,2,1);
zigbee_waveform_1_40MHz = resample(zigbee_waveform_1,2,1);
zigbee_waveform_2_40MHz = resample(zigbee_waveform_2,2,1);
zigbee_waveform_3_40MHz = resample(zigbee_waveform_3,2,1);

%zigbee_waveform_40MHz = (zigbee_waveform_1_40MHz + zigbee_waveform_2_40MHz + zigbee_waveform_3_40MHz);
zigbee_waveform_40MHz =  zigbee_waveform_1_40MHz;

wifi_waveform_40MHz = wifi_waveform_40MHz / max([real(wifi_waveform_40MHz); imag(wifi_waveform_40MHz)]);
%zigbee_waveform_40MHz = zigbee_waveform_40MHz * sqrt(mean(abs(wifi_waveform_40MHz).^2)/10) / sqrt(mean(abs(zigbee_waveform_40MHz).^2));
zigbee_waveform_40MHz = zigbee_waveform_40MHz / sqrt(mean(abs(zigbee_waveform_40MHz).^2));

% factor = 1;
% for L= 1:100
%     warpTransmitTwoStreams(wifi_waveform_40MHz, factor*zigbee_waveform_40MHz );
%     disp(L)
% end
% for L= 1:100
%     warpTransmitSignal(zigbee_waveform_40MHz);
%      disp(L)
% end
% for idx = 0:12


%% WARP 
for L= 1:50
    warpTransmitCurrentStreams(wifi_waveform_40MHz,zigbee_waveform_40MHz,20,10);
    disp(L)
end
% end
% for L= 1:100
%     warpTransmitSignal(wifi_waveform_40MHz);
%     disp(L)
% end
%% USRP write to file
%writeWiFiSignalTofile(txPPDU,'usrp/xfi_1200_20MHz.dat',1);
%writeWiFiSignalTofile(zigbee_waveform_1,'usrp/ble_20MHz.dat',1);



