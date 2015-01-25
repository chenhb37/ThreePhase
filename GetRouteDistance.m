function [ distance ] = GetRouteDistance(route,distances)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    len = size(route,2);
    distance = 0;
    for i = 1:len-1
        if route(i+1)==0
            break;
        end
        distance = distance + distances(route(i),route(i+1));
    end
end

