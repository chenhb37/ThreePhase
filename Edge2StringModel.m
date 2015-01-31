function sm = Edge2StringModel(x,customerNum,demands)
  sm =[];
  x = int32(x);
  nodeNum = sqrt(size(x,1)/2);
  depotNum = nodeNum - customerNum;
  counter = 1;
  for i = 1:depotNum
      j = depotNum+1;
      while j<=nodeNum
          if x((i-1)*nodeNum+j) > 0
              %·¢ÏÖÂ·¾¶
              sm(counter) = i;
              counter = counter+1;
              sm(counter) = j;
              counter = counter+1;
              x((i-1)*nodeNum+j) = x((i-1)*nodeNum+j)-1;
              prepre = i;
              pre = j;
              after = 1;
              while pre~= i
                  while after<=nodeNum &&(x((pre-1)*nodeNum+after) < 0.0000001 || x(nodeNum^2+(pre-1)*nodeNum+after)<=0)
                      after = after + 1;
                  end
                  if after > nodeNum
                      after = 1;
                      while x((pre-1)*nodeNum+after) < 0.0000001
                          after =after+1;
                      end
                  end
                  sm(counter) = after;
                  counter = counter+1;
                  x((pre-1)*nodeNum+after) = x((pre-1)*nodeNum+after)-1;
                  demands(pre) = 0;
                  prepre = pre;
                  pre = after;
                  after = 1;
              end
              j = j-1;
          end
          j = j+1;
      end
  end
end