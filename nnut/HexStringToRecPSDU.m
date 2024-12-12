% Covert the hex string extracted from raw captured (with
% ExtractRawDataCaptured.m) into bit array.
% Parameter: tframes: 1xN cell array, each cell is a hex string of psdu
% Return: recPSDUs: NxM matrix thatcontains PSDU in bit array. Each row of matrix is
% PSDU. The bit order are Left-MSB.
function [recPSDUs] = HexStringToRecPSDU(tframes)
    recPSDUs = [];
    for frameIdx = 1 : size(tframes,2)
        raw = tframes{frameIdx};
        raw = raw + 0;
        idNum = raw < 58 ;
        raw(idNum)  = raw(idNum)  - 48 ; 
        raw(~idNum) = raw(~idNum) - 87 ; 

        % remove space
        raw(raw < 0) = [];
        received = reshape(de2bi(raw, 'left-msb')',1,[]);
        recPSDUs = [recPSDUs; received];
    end
end