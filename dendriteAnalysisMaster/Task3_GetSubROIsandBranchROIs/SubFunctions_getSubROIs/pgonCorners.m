function corners = pgonCorners(BW,k,N)
%Method of detecting the corners in a binary image of a convex polygon with 
%a known number of vertices. Uses a linear programming approach.
%
%   corners = pgonCorners(BW,k)
%   corners = pgonCorners(BW,k,N)
%             
%IN:          
%             
%    BW: Input binary image    
%     k: Number of vertices to search for.     
%     N: Number of angular samples partitioning the unit circle (default=360).
%        Affects the resolution of the search.
%             
%OUT:         
%             
%   corners: Detected corners in counter-clockwise order as a k x 2 matrix.
   if nargin<3, N=360; end
  
    theta=linspace(0,360,N+1); theta(end)=[];
    IJ=bwboundaries(BW);
    IJ=IJ{1};
    centroid=mean(IJ);
    IJ=IJ-centroid;
    
    c=nan(size(theta));
    
    for i=1:N
        [~,c(i)]=max(IJ*[cosd(theta(i));sind(theta(i))]);
    end
    
    Ih=IJ(c,1); Jh=IJ(c,2);
    
    [H,~,~,binX,binY]=histcounts2(Ih,Jh,k);
     bin=sub2ind([k,k],binX,binY);
    
    [~,binmax] = maxk(H(:),k);
    
    [tf,loc]=ismember(bin,binmax);
    
    IJh=[Ih(tf), Jh(tf)];
    G=loc(tf);
    
    C=splitapply(@(z)mean(z,1),IJh,G);
    
    [~,perm]=sort( cart2pol(C(:,2),C(:,1)),'descend' );
    
    corners=C(perm,:)+centroid;