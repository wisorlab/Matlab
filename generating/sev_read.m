%This function should serve to read an sev file into a Matlab array (an N rows by 1 column matrix).    
%The quick and dirty way is to ignore the 40 bytes and read the rest of the file into an array, like this:
 
function [streamData, streamHeader] = sev_read(SevInputFile) %SevInputFile must be identified in single quotes and must be type sev.
                                        % for instance, the call should be:
                                        % sev_read('BupivSevTest.sev');

    FORMAT_MAP = containers.Map(...
        0:5,...
        {'float32','int32','int16','int8','float64','int64'});

    % open file
    fmt = '*float32'
    fid = fopen(SevInputFile, 'rb');
    
    
    fread(fid, 40, 'char'); % ignore the header
    display('are we there yet')
    streamData = fread(fid, inf, fmt) % read the streaming data
    display('yes')

    % create and fill streamHeader struct '
    streamHeader = [];

    streamHeader.fileSizeBytes   = fread(fid,1,'uint64');
    streamHeader.fileType        = char(fread(fid,3,'char')');
    streamHeader.fileVersion     = fread(fid,1,'char');
    
    

    if streamHeader.fileVersion < 2
    
        streamHeader.eventName  = fliplr(char(fread(fid,4,'char')')); % event name of stream
        
        streamHeader.channelNum        = fread(fid, 1, 'uint16'); % current channel of stream
        streamHeader.totalNumChannels  = fread(fid, 1, 'uint16'); % total number of channels in the stream
        streamHeader.sampleWidthBytes  = fread(fid, 1, 'uint16'); % number of bytes per sample
        reserved                 = fread(fid, 1, 'uint16');
        
        streamHeader.dForm      = FORMAT_MAP(bitand(fread(fid, 1, 'uint8'),7)); % data format of stream
        streamHeader.packSize   = fread(fid, 1, 'uint8'); % number of samples in a data block (should always be 1)
        streamHeader.decimate   = fread(fid, 1, 'uint8'); % used to compute actual sampling rate
        streamHeader.rate       = fread(fid, 1, 'uint16'); % always 512
        
        reserved = fread(fid, 1, 'uint64'); % tags
        reserved = fread(fid, 1, 'uint16');
        reserved = fread(fid, 1, 'uint8');
        
    end
    
    if streamHeader.fileVersion > 0
        % determine data sampling rate
        streamHeader.Fs = 2^(streamHeader.decimate) * 25000000 / 2^12;
    else
        streamHeader.dForm = 'float32';
    end
    
    % read rest of file into data array as correct format
    streamData = fread(fid, inf, ['*' streamHeader.dForm]); 
    
    % close file
    fclose(fid);
    
    if streamHeader.fileVersion > 0
        % verify streamHeader is 40 bytes
        dataSize = length(streamData) * streamHeader.sampleWidthBytes;
        streamHeaderSizeBytes = streamHeader.fileSizeBytes - dataSize;
        if streamHeaderSizeBytes ~= 40
            warning('streamHeader Size Mismatch -- %d bytes vs 40 bytes', streamHeaderSizeBytes);
        end
    end
end

