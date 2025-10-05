function[poss] = from_8_columnns_to_4(res,remBeads)

% Very simple program, takes in the 8 columns out of trackmem and makes 
% them into the only 4 columns we really need, x- and y-position, frame
% number and bead ID. 
%
% ADDITION: This function is a convenient place in the flow of the program
%           to remove unwanted bead trajectories based on min/max radius or
%           position on the screen. A list of trajectories previously
%           determined to be unwanted is passed to this function and only
%           beads not on this list are built into the reduced matrix
%           'poss'. This ensures that only the trajectories we want to
%           study are kept for the remainder of the program, including the
%           dedrifting portion. From this point onward the beads will have
%           new ID numbers that account for gaps due to removed
%           trajectories.
%           Will Hanna 31 July 2012
%
% INPUT : Matrix after trackmem
% OUTPUT : Same matrix with information from feature finding taken out.
nextRem = 1; % position in the list of bad trajectories
newID = 1; % new ID number to assign to kept bead
left = 1; % starting length of the poss matrix
j = 1;
for i = 1:max(res(:,8)) % for each bead
    start = j;
    while j <= length(res) && res(j,8) == i; % get length in frames of bead trajectory
        j = j + 1;
    end
    
    if nextRem <= length(remBeads) && i == remBeads(nextRem)  % bad beads are not added
        nextRem = nextRem + 1; % advance once into the bad trajectory list
    else % place bead in the poss matrix
        right = left + (j - start - 1);
        poss(left:right,1:2) = res(start:j-1,1:2);
        poss(left:right,3) = res(start:j-1,6);
        poss(left:right,4) = newID;
        newID = newID + 1;
        left = right + 1;
    end

end
