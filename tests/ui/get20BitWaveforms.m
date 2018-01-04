function [ i32X, i32Y ] = get20BitWaveforms( )

    % Set to 10 Hz
    dFreq = 10; % hz
    dTime = 0 : 24e-6 : 2;

    i32X = int32( 0.8 * 2^19 * sin(2 * pi * dFreq * dTime));
    i32Y = int32( 0.6 * 2^19 * cos(2 * pi * dFreq * dTime));

end

