function [desc,distances,demands] = EdgeReader(fileName)
%DATAREADER Summary of this function goes here
%   Detailed explanation goes here
 [fileId] = fopen(fileName);
 %[dimension satellites customers]
 nodeInfo = cell2mat(textscan(fileId,'%*s : %d',3,'HeaderLines',3)); 
 %[l1capacity l2capacity l1fleet l2fleet] 
 fleetInfo= cell2mat(textscan(fileId,'%*s : %d',2,'HeaderLines',3));
 temp = cell2mat(textscan(fileId,'%*s %d',2,'HeaderLines',1));
 fleetInfo = [fleetInfo;temp];
 %distance matrix
 distances = cell2mat(textscan(fileId,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f',nodeInfo(1),'HeaderLines',2));
 demands = cell2mat(textscan(fileId,'%*f %f',nodeInfo(1),'HeaderLines',3));
%  header = textscan(fileId,'%d %d %d %d',1,'delimiter',',');
%  nodeNum = header{1};
%  satelliteNum = header{2};
%  vehicleNum = header{3};
%  vehicleCapacity = header{4};
%  desc = [nodeNum,satelliteNum,vehicleNum,vehicleCapacity];
 desc = [nodeInfo;fleetInfo];
 fclose(fileId);
end
