% This is the first verison of XFi
% naive method of decoding the packet without the error awareness
% Also we assume perfect time synchronization,i.e. ZigBee and WiFi data
% start at th same time. 
%filename = 'data\delay\a6210_no_delay.txt';
filename = 'data\8812au\8812au_3800.txt';
tframes = ExtractRawDataCaptured(filename);
ht = wlanHTConfig('MCS',7);
ht.ChannelCoding = 'LDPC';
ht.PSDULength = 3800;

load('txPSDU_3800.mat')

payload = 1:6;
symbol_zigbee = generateUnlimitedZigBeeSignal(payload); %baseband signal in 4MHz
symbol_zigbee_20MHz = resample(symbol_zigbee,5,1);
average_chip_errors = [];

for frameIdx = 1 : size(tframes,2)

received = HexStringToRecPSDU(tframes(frameIdx));
received = received(1:3800*8);
received =  swapBits(received,8)'; %left-LSB 
%% reconstruct bits
scramInitBits = uint8([1; 0; 1; 1; 1; 0; 1]);
reconstruct_zigbee_4MHz = RecPSDUToWaveform(received,scramInitBits,ht);

nSymbs = 16+6*2;
[hamming_distance,average_chip_error] = calculateHammingDistances(symbol_zigbee,reconstruct_zigbee_4MHz,nSymbs);

if average_chip_error  > 10 %decoding error and decoded with other scramble init
    min_average_chip_err = 32;
    for seedIdx = 1:127
        scramInitBits = uint8(de2bi(seedIdx,7))';
        reconstruct_zigbee_4MHz_candidate = RecPSDUToWaveform(received,scramInitBits,ht);
        [hamming_distance,average_chip_error] = calculateHammingDistances(symbol_zigbee,reconstruct_zigbee_4MHz_candidate,nSymbs);
        if average_chip_error < min_average_chip_err
            min_average_chip_err =  average_chip_error;
            reconstruct_zigbee_4MHz = reconstruct_zigbee_4MHz_candidate;
        end
        if average_chip_error <= 10
            disp("find right scramble seed");
            break;
        end
    end
else
    min_average_chip_err =  average_chip_error;
end

average_chip_errors = [average_chip_errors min_average_chip_err];
fprintf("chipErr:%f\n", min_average_chip_err);
decodeOQPSKDSSS(reconstruct_zigbee_4MHz);

end

stem(average_chip_errors);