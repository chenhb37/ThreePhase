function [sm] = Gpu2StringModel(routes,rl)
%   把通过cuda利用gpu并行运行得出的解转换成string模型
%   routes: 通过cuda利用gpu并行运行得出的路径集合
%   rl: maxSolutionLen
sm = [];
len = size(routes,2);
start =1;
while start < len
    [~,index] = min(routes(start:start+rl-1));
    sm = [sm routes(start:start+index-2)];
    start = start+rl;
end
end

