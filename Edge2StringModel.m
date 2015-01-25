function sm = Edge2StringModel(x,customerNum)
  sm =[];
  nodeNum = sqrt(size(x,1)/2);
  depotNum = nodeNum - customerNum;
  counter = 1;
  for i = 1:depotNum
      for j = depotNum+1:nodeNum
          if x((i-1)*nodeNum+j) > 0
              %·¢ÏÖÂ·¾¶
              sm(counter) = i;
              counter = counter+1;
              sm(counter) = j;
              counter = counter+1;
              x((i-1)*nodeNum+j) = x((i-1)*nodeNum+j)-1;
              
              pre = j;
              after = 1;
              while pre~= i
                  while x((pre-1)*nodeNum+after) == 0
                      after = after + 1;
                  end
                  sm(counter) = after;
                  counter = counter+1;
                  x((pre-1)*nodeNum+after) = x((pre-1)*nodeNum+after)-1;
                  pre = after;
                  after = 1;
              end
          end
      end
  end
end