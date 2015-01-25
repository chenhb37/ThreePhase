function [desc,nodes,satellites,demands] = InstanceDataReader( fileName )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
 [fileId,message] = fopen(fileName);
 header = textscan(fileId,'%d %d %d %d',1,'delimiter',',');
 nodeNum = header{1};
 satelliteNum = header{2};
 vehicleNum = header{3};
 vehicleCapacity = header{4};
 desc = [nodeNum,satelliteNum,vehicleNum,vehicleCapacity];
 temp = textscan(fileId,'%s',1);
 nodes = textscan(fileId,'%d %f %f',nodeNum,'delimiter',',');
 temp = textscan(fileId,'%s',1);
 demands = textscan(fileId,'%d %d',nodeNum,'delimiter',',');
 temp = textscan(fileId,'%s',1);
 satellites = textscan(fileId,'%f %f',satelliteNum,'delimiter',',');
end

