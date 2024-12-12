% Calculate the demodulation Error
% Input: 
%       waveform_4MHz: the recovered zigbee waveform by XFi
function [chipErr,chipErrConf,symbolErr,frameErr,frameErrDecode] =  zigbeeDecodeError(waveform_4MHz,payload,softvalueConf_4MHz)
    
    %generate Standard ZigBee waveform 
    standardZigBee_4MHz = generateUnlimitedZigBeeSignal(payload); %baseband signal in 4MHz

    offset = 2;
    %chips of standard ZigBee
    c = standardZigBee_4MHz(2:end).*conj(standardZigBee_4MHz(1:end-1));
    standard_softvalue = atan(imag(c)./real(c));
    standard_chips = standard_softvalue(offset:2:end) > 0;
    
    %Quadrature Demod of received waveform
    c = waveform_4MHz(2:end).*conj(waveform_4MHz(1:end-1));
    received_softvalue = atan(imag(c)./real(c));
    received_chips = received_softvalue(offset:2:end) > 0;
    standard_chips = standard_chips(1:length(received_chips));
    
    %Confidence
    softvalueConf_2MHz = softvalueConf_4MHz(offset:2:end);
    softvalueConf_2MHz = softvalueConf_2MHz(1:length(received_chips));
    
    chipErr = sum(xor(received_chips,standard_chips)) / length(received_chips);
    chipErrConf = sum(xor(received_chips,standard_chips) & ~softvalueConf_2MHz) / sum(~softvalueConf_2MHz);
    
    %Symbol Err
    standard_symbols = decodeOQPSKDSSS(standardZigBee_4MHz);
    standard_symbols = standard_symbols(7:end-2); %skip preamble and CRC
    decoded_symbols = decodeOQPSKDSSSXFi(waveform_4MHz,softvalueConf_4MHz);
    decoded_symbols = decoded_symbols(7:end-2); 
    symbolErr = (sum(floor(standard_symbols/16) ~= floor(decoded_symbols/16)) + ...
                 sum(mod(standard_symbols,16) ~= mod(decoded_symbols,16)) ) ... 
                      / (2*length(standard_symbols));
                  
    standard_data = [];   decoded_data = [];
    for cb = 1:floor(length(standard_symbols)/7)
        standard_data = [standard_data  rsdecoder(standard_symbols(1+(cb-1)*7:cb*7))];
        decoded_data  = [decoded_data   rsdecoder(decoded_symbols(1+(cb-1)*7:cb*7))];
    end
    symbolErrDecode =(sum(floor(standard_data/16) ~= floor(decoded_data/16)) + ...
                        sum(mod(standard_data,16) ~= mod(decoded_data,16)) ) ... 
                         / (2*length(standard_data));
    %Frame Err
    frameErr = (symbolErr~=0);
    frameErrDecode = (symbolErrDecode~=0);
end