function [sm] = Gpu2StringModel(routes,rl)
%   ��ͨ��cuda����gpu�������еó��Ľ�ת����stringģ��
%   routes: ͨ��cuda����gpu�������еó���·������
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

