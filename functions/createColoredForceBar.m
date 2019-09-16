%% Create base profile (circle/square)
width = 0.15;
base_type = 'circle';

if strcmp(base_type, 'square') 
    q = linspace(0,2*pi,5) + pi/4;
    base = (width/2)*[cos(q); sin(q)];   % Base curve is a square
elseif strcmp(base_type, 'circle')
    % Base curve is a circle
    cir_res = 40;   % circle resolution (# pts)
    q = linspace(0, 2*pi, cir_res);
    base = (width/2)*[cos(q); sin(q)]; 
else
    error('base_type must be ''circle'' or ''square''')
end
  
%% create paths
[st_path_full, st_theta] = scalaTympaniMedialAxis(0.25);

% create offset paths
spacing = 0.55*width;
st_path1 = [offsetPolyline(st_path_full(1:2,:), -spacing); zeros(1, length(st_path_full))]; % 3D, but no Z component
st_path2 = [offsetPolyline(st_path_full(1:2,:),  spacing); zeros(1, length(st_path_full))];

% trim 10 degrees back from final angular depth
trim_deg = 10;
mag1_end = mag1.interp_angdepth(end)-trim_deg;
nomag1_end = nomag1.interp_angdepth(end)-trim_deg;
mag1_end_ind = find(mag1.interp_angdepth >= mag1_end, 1);
nomag1_end_ind = find(nomag1.interp_angdepth >= nomag1_end, 1);
max_ang_index1 = find(st_theta > mag1_end, 1);
max_ang_index2 = find(st_theta > nomag1_end, 1);

% interpolate path at angular depth points
st_path_mag1 = interp1(st_theta(1:max_ang_index1), st_path1(:,1:max_ang_index1)', mag1.interp_angdepth(1:mag1_end_ind));
st_path_nomag1 = interp1(st_theta(1:max_ang_index2), st_path2(:,1:max_ang_index2)', nomag1.interp_angdepth(1:nomag1_end_ind));

% map force to height (Z)
force_scale = 0;
st_path_mag1(:,3) = force_scale*data_mag1.Fmag_smooth(1:mag1_end_ind)';
st_path_nomag1(:,3) = force_scale*data_nomag1_mea.Fmag_smooth(1:nomag1_end_ind)';

% extrude path to create surface
[X1,Y1,Z1] = extrude(base, st_path_mag1, 0);   %cap = 2 for separate caps
[X2,Y2,Z2] = extrude(base, st_path_nomag1, 0); %cap = 2 for separate caps

%% plot
figure(12); clf(12); axis equal; hold on; grid off;

% plot extrusions
h1 = surf(X1,Y1,Z1);
h1.CData = repmat(data_mag1.Fmag_smooth(1:mag1_end_ind)', [length(base), 1]);
h2 = surf(X2,Y2,Z2);
h2.CData = repmat(data_nomag1_mea.Fmag_smooth(1:nomag1_end_ind)', [length(base), 1]);

% plot ST (2D)
st_end_ind = find(st_theta>720,1);
drawPolyline3d([st_path_full(1,1:st_end_ind); st_path_full(2,1:st_end_ind); zeros(1,st_end_ind)]', 'b')
shading flat
view(-90,90)
% view(90,-90)

% rescale colormap
cMap = hot(256+70);
% cMap = cool(256);
cMap = cMap(1:end-70,:);
dataMax = max(data_mag1.Fmag_smooth);
dataMin = min(data_mag1.Fmag_smooth);
centerPoint = 5;
scalingIntensity = 5;

x = 1:length(cMap); 
x = x - (centerPoint-dataMin)*length(x)/(dataMax-dataMin);
x = scalingIntensity * x/max(abs(x));
x = sign(x).* exp(abs(x));
x = x - min(x); x = x*511/max(x)+1; 
newMap = interp1(x, cMap, 1:512);
cmap_scaled = colormap(newMap);

set(gca,'xtick',[])
set(gca,'xticklabel',[])
set(gca,'ytick',[])
set(gca,'yticklabel',[])
set(gca,'ztick',[])
set(gca,'zticklabel',[])

cbar = colorbar;
cbar.Label.String = 'Force (mN)';
cbar.Label.FontSize = 14';

% plot end caps
% surf(CAPS1(1).X, CAPS1(1).Y, CAPS1(1).Z, 'linestyle','none', 'FaceColor',cmap_scaled(1,:));
% surf(CAPS1(2).X, CAPS1(2).Y, CAPS1(2).Z, 'linestyle','none', 'FaceColor',cmap_scaled(end,:));
% surf(CAPS2(1).X, CAPS2(1).Y, CAPS2(1).Z, 'linestyle','none', 'FaceColor',cmap_scaled(1,:));
% surf(CAPS2(2).X, CAPS2(2).Y, CAPS2(2).Z, 'linestyle','none', 'FaceColor',cmap_scaled(end,:));

%%
% x1 = mag1.interp_angdepth';
% y1 = [0.02; .98];
% [X1,Y1] = meshgrid(x1,y1);
% Z1 = repmat(data_mag1.Fmag_smooth', size(y1));
% 
% x2 = nomag1.interp_angdepth';
% y2 = [1.02; 1.98];
% [X2,Y2] = meshgrid(x2,y2);
% Z2 = repmat(data_nomag1_mea.Fmag_smooth', size(y2));
% 
% %%
% figure(5); clf(5); hold on;
% surf(X1,Y1,Z1);
% surf(X2,Y2,Z2);
% colormap(gray);
% shading flat
% grid off
% colorbar
% set(gca, 'color', [160 200 230]/255)
% view(2)
% ylim([0 10])
% 
% %%
% figure(6); clf(6); hold on;
% h = ribbon(mag1.interp_angdepth', data_mag1.Fmag_smooth);
% h.CData = data_mag1.Fmag_smooth;
% % ribbon(nomag1.interp_angdepth, data_nomag1_mea.Fmag_smooth)
% shading flat
% grid off