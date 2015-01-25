function [desc,nodes,satellites,demands] = DataReader(fileName)
%DATAREADER Summary of this function goes here
%   Detailed explanation goes here
 [fileId] = fopen(fileName);
 %[dimension satellites customers]
 nodeInfo = cell2mat(textscan(fileId,'%*s : %d',3,'HeaderLines',3)); 
 %[l1capacity l2capacity l1fleet l2fleet] 
 fleetInfo= cell2mat(textscan(fileId,'%*s : %d',2,'HeaderLines',3));
 temp = cell2mat(textscan(fileId,'%*s %d',2,'HeaderLines',1));
 fleetInfo = [fleetInfo;temp];
 %node sate
 nodes = cell2mat(textscan(fileId,'%*d %f %f',nodeInfo(1)-nodeInfo(2),'HeaderLines',2));
 satellites = cell2mat(textscan(fileId,'%*d %f %f',nodeInfo(2),'HeaderLines',2));
 demands = cell2mat(textscan(fileId,'%*f %f',nodeInfo(1)-nodeInfo(2),'HeaderLines',2));
%  header = textscan(fileId,'%d %d %d %d',1,'delimiter',',');
%  nodeNum = header{1};
%  satelliteNum = header{2};
%  vehicleNum = header{3};
%  vehicleCapacity = header{4};
%  desc = [nodeNum,satelliteNum,vehicleNum,vehicleCapacity];
 desc = [nodeInfo;fleetInfo];
end

