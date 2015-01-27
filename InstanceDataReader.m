function [desc,nodes,satellites,demands] = InstanceDataReader(fileName)
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
 nodes = cell2mat(textscan(fileId,'%*s %f %f %f -1',nodeInfo(1)-nodeInfo(2)-1,'HeaderLines',2));
 satellites = cell2mat(textscan(fileId,'%*s %f %f %*d -1',nodeInfo(2)));
 depot = cell2mat(textscan(fileId,'%*s %f %f %f -1',1));
 nodes = [depot;nodes];
 demands =nodes(1:nodeInfo(1)-nodeInfo(2),3);
 demands(1) =0;
 nodes =nodes(1:nodeInfo(1)-nodeInfo(2),1:2);
 
%  header = textscan(fileId,'%d %d %d %d',1,'delimiter',',');
%  nodeNum = header{1};
%  satelliteNum = header{2};
%  vehicleNum = header{3};
%  vehicleCapacity = header{4};
%  desc = [nodeNum,satelliteNum,vehicleNum,vehicleCapacity];
 desc = [nodeInfo;fleetInfo];
end