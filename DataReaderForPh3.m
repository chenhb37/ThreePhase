function [desc,nodes,satellites1,satellites2,demands] = DataReaderForPh3(fileName)
%DATAREADER Summary of this function goes here
%   Detailed explanation goes here
 [fileId] = fopen(fileName);
 %[dimension satellites customers]
 nodeInfo = cell2mat(textscan(fileId,'%*s : %d',4,'HeaderLines',3)); 
 %[l1capacity l2capacity l1fleet l2fleet] 
 fleetInfo= cell2mat(textscan(fileId,'%*s : %d',6,'HeaderLines',2));
 %node sate
 nodes = cell2mat(textscan(fileId,'%*d %f %f',nodeInfo(1)-nodeInfo(2)-nodeInfo(3),'HeaderLines',2));
 satellites2 = cell2mat(textscan(fileId,'%*d %f %f',nodeInfo(3),'HeaderLines',2));
 satellites1 = cell2mat(textscan(fileId,'%*d %f %f',nodeInfo(4),'HeaderLines',2));
 demands = cell2mat(textscan(fileId,'%*f %f',nodeInfo(1)-nodeInfo(2)-nodeInfo(3),'HeaderLines',1));
 desc = [nodeInfo;fleetInfo];
 fclose(fileId);
end