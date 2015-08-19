using Julimaps
using Params
using MeshModule

################################# SCRIPT FOR TESTING ###################################
tic();

max_tile_size = 0;
Ms = MeshModule.makeNewMeshSet();
sr = readdlm("W001_sec21_offsets.txt");

#sr = readdlm(joinpath("input_images", "W001_sec20", "W001_sec20_offsets.txt"))


@time for i in 1:num_tiles
	path = string("./W001_sec21/", sr[i, 1]);
	row = sr[i, 2];
	col = sr[i, 3];
	di = sr[i, 4];
	dj = sr[i, 5];
	MeshModule.addMesh2MeshSet!(MeshModule.Tile2Mesh(path, (1, 21, i), (row, col), di, dj, false, mesh_length, mesh_coeff), Ms);
	meshImage = MeshModule.getMeshImage(Ms.meshes[i]);
	max_size = max(size(meshImage, 1), size(meshImage, 2));
	if max_tile_size < max_size max_tile_size = max_size; end
end
	imageArray = SharedArray(Float64, max_tile_size, max_tile_size, num_tiles);

@time for k in 0:num_procs:num_tiles
	@sync @parallel for l in 1:num_procs
	i = k+l;
	if i > num_tiles return; end;
	meshImage = MeshModule.getMeshImage(Ms.meshes[i]);
	imageArray[1:size(meshImage, 1), 1:size(meshImage, 2), i] = meshImage;
	end
end

print("Initialisation, "); toc(); println();

tic();
adjacent_pairs = Pairings(0);
diagonal_pairs = Pairings(0);

for i in 1:Ms.N, j in 1:Ms.N
	if MeshModule.isAdjacent(Ms.meshes[i], Ms.meshes[j]) push!(adjacent_pairs, (i, j)); end
	if MeshModule.isDiagonal(Ms.meshes[i], Ms.meshes[j]) push!(diagonal_pairs, (i, j)); end
end

pairs = vcat(adjacent_pairs, diagonal_pairs);

@time for k in 0:num_procs:length(pairs)
	toFetch = @sync @parallel for l in 1:num_procs
	ind = k + l;
	if ind > length(pairs) return; end
	(i, j) = pairs[ind];
	return MeshModule.Meshes2Matches(imageArray[:, :, i], Ms.meshes[i], imageArray[:, :, j], Ms.meshes[j], block_size, search_r, min_r);
	end
	for i = 1:length(toFetch)
		M = fetch(toFetch[i])
		if typeof(M) == Void continue; end
		MeshModule.addMatches2MeshSet!(M, Ms);
	end
end

print("Blockmatching, "); toc(); println();



@time MeshModule.solveMeshSet!(Ms, match_coeff, eta_grad, grad_threshold, eta_newton, newton_threshold);

disps = Points(0);

for k in 1:Ms.M
	for i in 1:Ms.matches[k].n
		w = Ms.matches[k].dst_weights[i];
		t = Ms.matches[k].dst_triangles[i];
		p = Ms.matches[k].src_pointIndices[i];
		src = Ms.meshes[MeshModule.findIndex(Ms, Ms.matches[k].src_index)]
		dst = Ms.meshes[MeshModule.findIndex(Ms, Ms.matches[k].dst_index)]
		p1 = src.nodes_t[p];
		p2 = dst.nodes_t[t[1]] * w[1] + dst.nodes_t[t[2]] * w[2] + dst.nodes_t[t[3]] * w[3]
		push!(disps, p2-p1);
	end
end
@time MeshModule.MeshSet2JLD("solvedMesh(1,21,0).jld", Ms);


####### LEGACY CODE FOR PAIR TESTING #############

#Ap = "./EM_images/Tile_r4-c2_S2-W001_sec20.tif";
#dAi = 21906;
#dAj = 36429;

#Bp = "./EM_images/Tile_r4-c3_S2-W001_sec20.tif";
#dBi = 10000#29090; # 2908.6;
#dBj = 10000#36251; # 3624.3;


#=

Ms = makeNewMeshSet();
@time Am = MeshModule.Tile2Mesh(Ap, (1, 2, 42), (4, 2), dAi, dAj, false, mesh_length, mesh_coeff);
@time Bm = MeshModule.Tile2Mesh(Bp, (1, 2, 43), (4, 3), dBi, dBj, false, mesh_length, mesh_coeff);
@time A = MeshModule.getMeshImage(Am);
@time B = MeshModule.getMeshImage(Bm);
@time Mab = MeshModule.Meshes2Matches(A, Am, B, Bm, block_size, search_r, min_r);
@time Mba = MeshModule.Meshes2Matches(B, Bm, A, Am, block_size, search_r, min_r);

@time MeshModule.addMesh2MeshSet!(Am, Ms);
@time MeshModule.addMesh2MeshSet!(Bm, Ms);
@time MeshModule.addMatches2MeshSet!(Mab, Ms);
@time MeshModule.addMatches2MeshSet!(Mba, Ms);
=#
