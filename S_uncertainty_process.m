% 这个地方只有一个场景
load curve
w = 0;
% prob = prob(1,1,1);
% for idemand = 1:size(prob,1)
%     for iwind = 1:size(prob,2)
%         for isolar = 1:size(prob,3)
%             w = w + 1;
%             Para.scenario(w).prob = prob(idemand,iwind,isolar)/sum(sum(sum(prob)));
%             Para.scenario(w).normD = demandcluster(:,idemand)/mean(mean(demandcluster));
%             Para.scenario(w).normW = windcluster(:,iwind)/mean(mean(windcluster))/3;
%             Para.scenario(w).normS = solarcluster(:,isolar)/mean(mean(solarcluster))/4;
%         end 
%     end 
% end
w  = w+1;
Para.scenario(w).normD = mean(demandcluster,2)/mean(mean(demandcluster,2));
Para.scenario(w).normW = mean(windcluster,2)/mean(mean(windcluster))/3;
Para.scenario(w).normS = mean(solarcluster,2)/mean(mean(solarcluster))/4;

Num.S = 1;
Num.T = size(demandcluster,1);

