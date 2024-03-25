function [] = F_plot_Pareto(ifsave, Result_Pareto)
    set(groot,'defaultfigurePosition',[200 200 480 380]);
%     set(groot,'defaultLegendFontName','Times New Roman');
    set(groot,'defaultLegendFontSize',12);
    set(groot,'defaultAxesFontSize',11);
%     set(groot,'defaultFontSize',14);

%     set(groot,'defaultAxesFontWeight','bold');
    set(groot,'defaultAxesFontName',['Simsun']);
    set(0,'defaultfigurecolor','w'); %设置背景颜色为白色
    version_suffix =  '';            
    Picture_root_folder = ['Picture', version_suffix];  
    mkdir(Picture_root_folder);
    Picture_folder = Picture_root_folder;
%     Picture_folder = [Picture_root_folder,'/',save_name];
%     mkdir(Picture_folder);
    %% 画出SW, surplus的帕累托前沿(1)
    
    figure(1)
    plot([Result_Pareto.SW], [Result_Pareto.cap_surplus],'LineWidth',2)
%     matrix_plot = sortrows([[Result_ParetoBBSW(solveindex).surplus]
%     solveindex = find([solution_ParetoBBSW.problem] == 0); % 要找到有解的,所以soluton问题要查看是怎么回事
%     [Result_ParetoBBSW(solveindex).welfare]]',1);
%     plot(matrix_plot(:,1),matrix_plot(:,2));
    grid on
    xlabel('全市场社会福利');
    ylabel('全市场回收的容量成本(收支盈余)');
%     title('收支盈余和社会福利的权衡')
    if ifsave
        print('-dpng','-r1000',[Picture_folder,'/','SW_surplus_Pareto.png']);
        saveas(1,[Picture_folder,'/','SW_surplus_Pareto.jpg'])
    end
    %% 画出RelaxSW,RelaxBB的帕累托前沿(1)
    figure(2)
    RelaxSW = (Result_Pareto(1).SW - [Result_Pareto.SW])/Result_Pareto(1).SW;
    RelaxBB = -[Result_Pareto.cap_surplus]/Result_Pareto(1).SW;
    plot(RelaxSW, RelaxBB,'LineWidth',2)
    grid on
    xlabel('社会福利松弛量');
    ylabel('收支平衡松弛量');
%     title('社会福利和收支平衡松弛量的权衡')
    if ifsave
        print('-dpng','-r1000',[Picture_folder,'/','RelaxSW_RelaxBB_Pareto.png']);
        saveas(2,[Picture_folder,'/','RelaxSW_RelaxBB_Pareto.jpg'])
    end
    %% 画出各项随着scale的变化
    figure(3)
    data_matrix = [[Result_Pareto.cap_surplus];...
        [Result_Pareto.D_capC];[Result_Pareto.R_capI];[Result_Pareto.ESS_capI]];
    %[Result_Pareto.SW];
    plot([Result_Pareto.scale],data_matrix,'LineWidth',2)
%     matrix_plot = sortrows([[Result_ParetoBBSW(solveindex).surplus]
%     solveindex = find([solution_ParetoBBSW.problem] == 0); % 要找到有解的,所以soluton问题要查看是怎么回事
%     [Result_ParetoBBSW(solveindex).welfare]]',1);
%     plot(matrix_plot(:,1),matrix_plot(:,2));
    grid on
    xlabel('容量成本放缩倍数');
    ylabel('全市场的各项福利情况');
%     title('市场福利情况随容量成本放缩倍数的变化')
    legend('收支盈余','负荷容量成本账单','新能源容量收入','储能容量收入','Location','NorthWest');
    legend('boxoff');
    if ifsave
        print('-dpng','-r1000',[Picture_folder,'/','F_scale_welfare.png']);

        saveas(3,[Picture_folder,'/','F_scale_welfare.jpg'])
    end

    %% 画出各项随着scale的变化
    figure(4)
    
    [ax,p1,p2] = plotyy([Result_Pareto.scale],[Result_Pareto.SW], ...
        [Result_Pareto.scale],[Result_Pareto.cap_surplus],'plot','plot');
    p1.LineWidth = 2;
    p2.LineWidth = 2;
    set(ax(1),'XColor','k','YColor','b'); %设置x轴为黑色，左边y（也就是y1）轴为蓝色
    set(ax(2),'XColor','k','YColor','r'); %设置x轴为黑色，右边y（也就是y2）轴为红色

    xlabel('容量成本放缩倍数');
    ylabel(ax(1),'社会福利,元');
    ylabel(ax(2),'收支盈余,元');
%     set(ax,'Position',[0.16,0.16,0.65,0.7])
%     title('市场福利情况随容量成本放缩倍数的变化');
    set(p1,'linestyle','-','color','b');
    set(p2(1),'linestyle','-','color','r');
%     set(p2(2),'linestyle','-','color','r');
    h = legend('社会福利','收支盈余','Location','Best','NumColumns',1);
    legend('boxoff')
    set(ax(1),'ylim',[2.15e+06,2.20e+06]);
    set(ax(2),'ylim',[0,4e+05]);
    grid on 
    set(ax(1),'yTick',[2.15e+06:0.01e+06:2.20e+06]);
    set(ax(2),'yTick',[0:0.8e+05:4e+05]);
    % exportgraphics(gca,'演示性Q_1(X)和M_1(X)的关系_1..jpg','Resolution',300)
    print('-dpng','-r1000','F_scale_welfare_2.png');





end