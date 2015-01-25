function [ totalDemand ] = GetRouteDemand(route,demands )
       totalDemand = 0;
       for i = 1:size(route,2)
           if route(i)==0
               break;
           end
           totalDemand = totalDemand + demands(route(i));
       end
end

