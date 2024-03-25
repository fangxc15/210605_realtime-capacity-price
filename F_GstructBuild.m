function generator = F_GstructBuild(Num, RawData_Supply)
%   本函数用于把输入Supply数据建立机组的结构体数据，方便调用
%   本函数创建于20171120 11:33
generator = [];
    for i =1 : Num.I
       generator(i).GNum = RawData_Supply(i,1);
       generator(i).FNum = RawData_Supply(i,2); 
       generator(i).bus = RawData_Supply(i,3); 
       generator(i).Gmax = RawData_Supply(i,4);
       generator(i).Gmin = RawData_Supply(i,5);
       generator(i).type = RawData_Supply(i,6);
       generator(i).Tdownmin = RawData_Supply(i,7);
       generator(i).Tupmin = RawData_Supply(i,8);
       generator(i).OnCost = RawData_Supply(i,9);
       generator(i).eff = RawData_Supply(i,10);
       generator(i).Z_start = RawData_Supply(i,11);
       generator(i).upstream = RawData_Supply(i,12);%若为0，则没有上游水电站
       generator(i).delay =  RawData_Supply(i,13);
       generator(i).S = RawData_Supply(i,14);
       generator(i).pu = RawData_Supply(i,15);
       generator(i).pd = RawData_Supply(i,16);
       generator(i).onmax = RawData_Supply(i,17);
       generator(i).downmax = RawData_Supply(i,18);
       generator(i).ini_status = RawData_Supply(i,19);
       Num.genB = size(RawData_Supply,2) - 19;
       generator(i).cost = RawData_Supply(i,20:19 + Num.genB);


    end





end 
