function noderelation = F_buildnoderelation(Num,Para)
    for n = 1:Num.N
        noderelation(n).Bindex = [];
        noderelation(n).Nindex = [];
    end

    for b = 1:Num.Branch
        node1 = Para.branch(b).Node1;
        node2 = Para.branch(b).Node2;
        noderelation(node1).Nindex = [noderelation(node1).Nindex,node2];
        noderelation(node1).Bindex = [noderelation(node1).Bindex,b];
        noderelation(node2).Nindex = [noderelation(node2).Nindex,node1];
        noderelation(node2).Bindex = [noderelation(node2).Bindex,b];
    end 
end