 function [x,fval,exitflag,output] = AllocatePhaseCplex(nodeNum,depotNum,vehicleNum,capacity,distances,demands)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
       %将其转换成可用下面的数学模型进行求解的问题。
       srCost = 0;
       y = zeros(depotNum,nodeNum-depotNum);
       for i = depotNum+1:nodeNum
           if demands(i) > capacity
               v = floor(demands(i)/capacity);
               %选择一个最近的
               ds = distances(i,1:depotNum);
               [~,index] = min(ds);
               while vehicleNum(index) - v < 0 
                   ds(index) = 100000;
                   [~,index] = min(ds);
               end
               vehicleNum(index) = vehicleNum(index) - v;
               y(index,i) = v*capacity;
               demands(i) = demands(i) - v*capacity;
               srCost = v*2*distances(1,i);
           end
       end
       
      %% x = cplexmilp(f,Aineq,bineq,Aeq,bep,sostype,sooind,soswt,lb,ub,ctype)
       %    min fx
       %    Aineq * x <= bineq
       %    Aeq * x  = beq
       %    lb<= x <= ub
       %    x is the ctype
       
       %     1,sum(x(i,j)) >= 1   i= depotNum+1,...nodeNum
       %     2,1<= sum(x(i,j)) <= Vnum   i= 1,2,...,depotNum
       %     3,sum(x(i,j)) -sum(x(j,i)) = 0, i= 1,2,...,nodeNum; 
       %     4,sum(y(j,i)) - sum(y(i,j)) = d(i), i=depotNum+1,...,nodeNum
       %     5,y(i,j) <= capacity*x(i,j), i,j = 1,2,...,nodeNum
       %     6,0<=x(i,j)<=1 is Type B
       %     7,0<=y(i,j)<=capacity is type I
       % construct the f 
      f = zeros(1,nodeNum*nodeNum*2);
      c = 1;
      for i = 1:nodeNum
          for j =1:nodeNum
              f((i-1)*nodeNum+j) = c*distances(i,j);
          end
      end
      % construct the Aineq,bineq
      Aineq = zeros(nodeNum*nodeNum+nodeNum,nodeNum*nodeNum*2);
      bineq = zeros(nodeNum*nodeNum+nodeNum,1);
%       Aineq = zeros(nodeNum*nodeNum+depotNum,nodeNum*nodeNum*2);
%       bineq = zeros(nodeNum*nodeNum+depotNum,1);
      % y(i,j) <= capacity*x(i,j)
      for i = 1:nodeNum
          for j = 1:nodeNum
              if i~=j
                Aineq((i-1)*nodeNum+j,nodeNum*nodeNum+(i-1)*nodeNum+j) = 1;
                Aineq((i-1)*nodeNum+j,(i-1)*nodeNum+j) = -1*capacity;
              end
          end
      end
      % sum(x(i,j)) <=vehicleNum, i = 1,2,...,depotNum
      for i = nodeNum*nodeNum+1:nodeNum*nodeNum+depotNum
          depot = i - nodeNum*nodeNum;
          for j =1:nodeNum
             if depot~=j
              Aineq(i,(depot-1)*nodeNum+j) = 1;   
             end
          end
           bineq(i,1) = vehicleNum(depot);
      end
      % -sum(x(i,j))<= -1 即 sum(x(i,j)) >=1, i= depotNum+1,...,nodeNum;
      for i = nodeNum*nodeNum+depotNum+1:(nodeNum+1)*nodeNum
          cus = i - nodeNum*nodeNum;
          for j =1:nodeNum
              if cus~=j
                 Aineq(i,(cus-1)*nodeNum+j)= -1;
              end
          end
           bineq(i,1) = -1;
      end
         % construct the Aeq and beq
      Aeq = zeros(2*nodeNum - depotNum,nodeNum*nodeNum*2);
      beq = zeros(2*nodeNum - depotNum,1);
      %constraint 3
      for i = 1:nodeNum
           for j = 1:nodeNum
               if i~=j
                   Aeq(i,(i-1)*nodeNum+j) = 1;
                   Aeq(i,(j-1)*nodeNum+i) = -1;
               end
           end
      end
      %constraint 4   
      for i = nodeNum+1:2*nodeNum-depotNum
            cus = i - nodeNum + depotNum;
            for j = 1:nodeNum
                if cus~=j
                    Aeq(i,nodeNum*nodeNum+(j-1)*nodeNum+cus) = 1;
                    Aeq(i,nodeNum*nodeNum+(cus-1)*nodeNum+j) = -1;
                end
            end
             beq(i,1) = demands(cus);
      end
      %constraint 1
%       for i = 2*nodeNum-depotNum+1:3*nodeNum - 2*depotNum
%           cus = i -2*nodeNum+2*depotNum;
%           for j =1:nodeNum
%               Aeq(i,(j-1)*nodeNum+cus)= 1;
%           end
%           beq(i,1) = 1;
%       end
      
      % define the lb,ub and ctype
      lb = zeros(size(f));
      ub = zeros(size(f));
      ctype = '';
      for i = 1:nodeNum*nodeNum
           ub(i) = 1;
           ctype(i) = 'B';
      end
      for i = nodeNum*nodeNum+1:2*nodeNum*nodeNum
           ub(i) = capacity;
           ctype(i) = 'I';
      end
      
      % call the cplexmilp
      [x,fval,exitflag,output] = cplexmilp(f,Aineq,bineq,Aeq,beq,[],[],[],lb,ub,ctype);
      for i = 1:depotNum
         for j = 1:nodeNum - depotNum
              cus = j+depotNum;
              if y(i,j)>0
                  v = y(i,j)/capacity;
                  x((i-1)*nodeNum+cus+nodeNum^2) =  x((i-1)*nodeNum+cus+nodeNum^2)+ y(i,j);
                  x((i-1)*nodeNum+cus) =  x((i-1)*nodeNum+cus)+v;
                  x((cus-1)*nodeNum+cus) = x((cus-1)*nodeNum+cus)+v;
              end
         end
      end
      fval = fval+srCost;
end

