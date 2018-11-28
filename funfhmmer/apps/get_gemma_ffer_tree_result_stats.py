#!/usr/bin/env python
'''
This script generates a table summarising the gemma tree results and ffer results for a set of SFs by calculating the following values for each SF:
- max Evalue of GeMMA tree
- min Evalue of GeMMA tree
- max Evalue at which the last FFer merge takes place in GeMMA tree
- no. of tree steps between root (max Evalue) of tree and last FFer merge step
- SF no. of sequences
- SF starting cluster number
- SF funfam no.
- jobtime for running FFer on GeMMA tree
- (TBA) jobtime for running GeMMA 

'''
import sys
import re
import os
import glob

if len(sys.argv) != 3 :
	print("USAGE: python $0 <DIR_CONTAINING_SF_FFER_RESULTS> <DIR_CONTAINING_SF_GEMMA_SF_RESULTS>.")
	sys.exit()

ffer_dir = sys.argv[1]
gemma_dir = sys.argv[2]

##print("")
##print("Projectdir:", dirname)

print( 'SF', 'max_evalue_tree', 'min_evalue_tree', 'last_evalue_merge_evalue_ffer', 'tree_steps_from_root_to_last_merge', 'num_sequences', 'starting_cluster_num', 'funfam_num', sep = '\t')

def count_sf_sequences( path, extension ):

	count_sequences=0
	files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]
	for cluster in files:
		if cluster.endswith(extension):
			clusterfilename = path + "/" + cluster
			clusterfile  = open(clusterfilename, 'r').read()
			cluster_sequence_num = clusterfile.count('>')
##			print(clusterfilename, cluster_sequence_num)
			count_sequences += cluster_sequence_num	
	return(count_sequences)



def count_cluster_num( path, extension ):
	
	count_cluster=0
	files = [f for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]
	##files = glob.glob( path +'\\*.*')
	for cluster in files:
		if cluster.endswith(extension):
			count_cluster += 1
			
	return(count_cluster)

def get_max_merge_evalue_for_SF( sf, logfile ):
	
	#print("Searching for max. merge E-value for: ", sf)
	sflog = open(logfile, "r")
	merged_evalues=[]
	all_evalues=[]
	count=0
	last_merge_linecount= 0
	
	for line in sflog:
		
		regex1 = re.compile('#')
		regex3 = re.compile('JOBTIME')

		if (regex1.search(line) == None):
			
			#print("line does not contain #:", line)
			values = line.split()
			merge_node = values[4]
			evalue = values[5]
			ffer_action = values[7]
			all_evalues.append(float(evalue))
			count += 1
			regex2 = re.compile('^nomerge')
			
			if (regex2.search(ffer_action) == None):
				
				#print("%s at evalue %s has been merged - %s"% (merge_node, evalue, ffer_action))
				merged_evalues.append(float(evalue))
				last_merge_linecount = count
			#else:
				#print("%s at evalue %s has NOT been merged - %s"% (merge_node, evalue, ffer_action))
			
		elif (regex3.search(line) != None):
#			print("line contains # JOBTIME:", line)
			tabs = line.split()
			jobtime = tabs[4]
			
	sflog.close()
	
	diff_lastmerge_endoftree = count - last_merge_linecount
	
	if (merged_evalues):
		max_merge = max(merged_evalues)
		return( min(all_evalues), max(all_evalues), max_merge, diff_lastmerge_endoftree, jobtime)
	else:
		return( min(all_evalues), max(all_evalues), 0, diff_lastmerge_endoftree, jobtime)
	

#logfiles = [f for f in os.listdir(dirname) if os.path.isfile(os.path.join(dirname, f))]
for root, dirs, files in os.walk(ffer_dir):
	for logfile in files:
		if logfile.endswith('.LOG'):
			#print(logfile)
			base=os.path.basename(logfile)
			sfname=os.path.splitext(base)[0]
			#print(filename)
			sflog_fullname = ffer_dir + "/" + sfname + "/" + logfile
			#print(sflog_fullname)
			values = get_max_merge_evalue_for_SF( sfname, sflog_fullname )
			
			funfam_path = ffer_dir + "/" + sfname + "/" + "funfam_alignments"
			funfam_num = count_cluster_num( funfam_path, '.aln')
			
			sf_sequence_num = count_sf_sequences( funfam_path, '.aln')
			
			sc_path = gemma_dir + "/" + sfname + "/simple_ordering.hhconsensus.windowed/starting_cluster_alignments"
			starting_cluster_num = count_cluster_num( sc_path, '.aln')
			
			print(sfname, values[0], values[1], values[2], values[3], values[4], sf_sequence_num, starting_cluster_num, funfam_num, sep = '\t')
#			sys.exit()
			
			
			


	


