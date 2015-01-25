classdef Node
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    properties
        ID;
        demand;
        coor_x;
        coor_y;
    end
    methods
        function obj = Node(id,demand,coor_x,coor_y)
            obj.ID = id;
            obj.demand = demand;
            obj.coor_x = double(coor_x);
            obj.coor_y = double(coor_y);
        end
        function [distance] = GetDistance(obj,node)
            distance = sqrt((obj.coor_x - node.coor_x)^2+(obj.coor_y-node.coor_y)^2);
        end
    end
    
end

