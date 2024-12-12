% decode BLE from WiFi Capture without error awareness
% bottomline for XFi BLE
filename = './data/ble/FullGI/sync/a6210_cc2650_3.txt';
%filename = './data/ble/ShortGI/warp/a6210_warp_sgi_12000_ble.txt';
tframes = ExtractRawDataCaptured(filename);
ht = wlanHTConfig('MCS',7);
ht.ChannelCoding = 'LDPC';
ht.PSDULength = 12000;
%ht.GuardInterval = 'Short';

load('txPSDU_12000_empty.mat')

%payload =  '0123456789ABCDEF';
payload = '00010203040506070809'; 
ble_waveform_4MHz = generateBLEwaveform(payload); %baseband signal in 4MHz
ble_waveform_4MHz = ble_waveform_4MHz(12:end);
ble_waveform_2MHz = resample(ble_waveform_4MHz,1,2);
[bits,decoded_bytes] = decodeGFSK(ble_waveform_2MHz);

confidence_2MHz = getBLESampleConfidence(ht,1);

for frameIdx = 1 : size(tframes,2)
    %reverse the bit order to Left-LSB
    received = HexStringToRecPSDU(tframes(frameIdx));
    received = received(1:ht.PSDULength*8);
    received = swapBits(received,8)'; %left-LSB 

    %recover the scrambler
    %scramInitTransmitted =  uint8([1; 0; 1; 1; 1; 0; 1]);
    scramInitTransmitted =  uint8([1 ;0; 0; 0; 1; 1; 1]);
    seed =recoverScramblerCodedbits(scramInitTransmitted,received,ht);
    
    waveform_20MHz_ch1 = recPSDUToBLEWaveform(received,seed,ht,1);
    waveform_2MHz_ch1 = waveform_20MHz_ch1(1:10:end);
    
    subplot(4,1,1);
    plot(real(waveform_2MHz_ch1));
    hold on;
    plot(imag(waveform_2MHz_ch1));

    title("recovered BLE signal")
    
    subplot(4,1,4);
    [offset,distances] = blePreambleDetector(waveform_2MHz_ch1,confidence_2MHz);
    stem(distances);
    title(min(distances))
    %disp(offset)
    
    subplot(4,1,2);
    [bits_decode, bytes]= decodeGFSK(waveform_2MHz_ch1(offset:end));
    biterr = abs(bits-bits_decode(1:length(bits)));
    stem(biterr);
    
    subplot(4,1,3);
    confidence = confidence_2MHz(offset:2:end);
    conf = confidence(1:length(bits));
    stem(conf);
    
    %error 
    nNerr = sum(conf & biterr);
    nNerr2 = sum(~conf & biterr);
    fprintf('%d : %d\n',nNerr,nNerr2);
%    disp(sum(biterr))
%     if ch == 1
%         [offset,distances] = zigbeePreambleDetector(waveform_4MHz_ch1,softvalueConfidence_ch1);
%         if length(waveform_4MHz_ch1) > 36*64 + offset
%             decoded_symbols = decodeOQPSKDSSSXFi(waveform_4MHz_ch1(offset:offset+36*64),softvalueConfidence_ch1(offset:end));
%         end 
%     else
%         [offset,distances] = zigbeePreambleDetector(waveform_4MHz_ch2,softvalueConfidence_ch2);
%         decoded_symbols = decodeOQPSKDSSSXFi(waveform_4MHz_ch2(offset:end),softvalueConfidence_ch2(offset:end));
%     end
    pause(1)
 end