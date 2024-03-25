
x = sdpvar(1,1);
Cons = [x >= 1];
obj = x;
ops = sdpsettings('solver','gurobi','verbose',1,'saveyalmipmodel',1);
solution = optimize(Cons,obj,ops);
% Resultcal_nocap = F_calwelfare(Result_nocap, Para_modify,Para, Num, Iter);