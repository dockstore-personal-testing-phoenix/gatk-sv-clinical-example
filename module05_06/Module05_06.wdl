version 1.0
# based on fused batch integration + clean vcf snapshot 22
# https://portal.firecloud.org/#methods/Talkowski-SV/fused_04b_batch_integration_05_cleanVCF/22/wdl
# and preprocessing snapshot 12
# https://portal.firecloud.org/#methods/Talkowski-SV/04b_preprocess/12/wdl

# Copyright (c) 2018 Talkowski Lab

# Contact Ryan Collins <rlcollins@g.harvard.edu>

# Distributed under terms of the MIT License


#This is a master wrapper WDL that fuses the third rebuild of module 04b from Fall 2018 
# with the per-chromosome cleanVcf processing directly. This obviates the need
# to merge the per-chromosome VCFs at the end of 04b prior to being sharded immediately
# after at the beginning of cleanVcf


#Imports:
# based on snapshot 11
import "05_06_vcf_cluster_single_chrom.wdl" as VcfClusterContig
# based on snapshot 28
import "05_06_resolve_complex_sv.wdl" as ResolveComplexContig
# based on snapshot 12
import "05_06_scatter_cpx_genotyping.wdl" as GenotypeComplexContig
# based on snapshot 93
import "05_06_clean_vcf.wdl" as CleanVcfContig
# based on snapshot 75
import "05_06_master_vcf_qc.wdl" as VcfQc

import "05_06_common_mini_tasks.wdl" as MiniTasks

workflow Module05_06 {
  input {
    File raw_sr_bothside_pass
    File raw_sr_background_fail
    Float min_sr_background_fail_batches
    File fam_file_list

    File pesr_vcf_list
    File pesr_vcf_idx_list
    File depth_vcf_list
    File depth_vcf_idx_list
    Array[String] samples
    File contig_list
    Int max_shards_per_chrom
    Int min_variants_per_shard
    File cytobands
    File cytobands_idx
    File discfile_list
    File discfile_idx_list
    File bincov_list
    File bincov_idx_list
    File mei_bed
    File pe_blacklist
    File pe_blacklist_idx
    File depth_blacklist
    File depth_blacklist_idx
    String prefix
    File trios_fam_file
    File? sanders_2015_tarball
    File? collins_2017_tarball
    File? werling_2018_tarball
    File rf_cutoffs
    File batches_list
    File depth_gt_rd_sep_list
    File medianfile_list
    File sampleslist_list
    Int max_shards_per_chrom_clean_vcf_step1
    Int min_records_per_shard_clean_vcf_step1
    Int samples_per_clean_vcf_step2_shard
    File? outlier_samples_list
    Int? random_seed
    Boolean include_external_benchmarking

    String sv_base_mini_docker
    String sv_pipeline_docker
    String sv_pipeline_rdtest_docker
    String sv_pipeline_qc_docker

    # overrides for local tasks
    RuntimeAttr? runtime_overide_get_discfile_size
    RuntimeAttr? runtime_override_update_sr_list
    RuntimeAttr? runtime_override_merge_pesr_depth
    RuntimeAttr? runtime_override_breakpoint_overlap_filter
    RuntimeAttr? runtime_override_integrate_resolved_vcfs
    RuntimeAttr? runtime_override_rename_variants

    # overrides for mini tasks
    RuntimeAttr? runtime_override_clean_bothside_pass
    RuntimeAttr? runtime_override_clean_background_fail
    RuntimeAttr? runtime_override_merge_fam_file_list
    RuntimeAttr? runtime_override_make_cpx_cnv_input_file
    RuntimeAttr? runtime_override_subset_inversions
    RuntimeAttr? runtime_override_concat_midpoint_vcfs
    RuntimeAttr? runtime_override_concat_final_vcfs
    RuntimeAttr? runtime_override_concat_cleaned_vcfs

    # overrides for VcfClusterContig
    RuntimeAttr? runtime_override_join_vcfs
    RuntimeAttr? runtime_override_subset_bothside_pass
    RuntimeAttr? runtime_override_subset_background_fail
    RuntimeAttr? runtime_override_subset_sv_type
    RuntimeAttr? runtime_override_concat_sv_types
    RuntimeAttr? runtime_override_shard_vcf_precluster
    RuntimeAttr? runtime_override_svtk_vcf_cluster
    RuntimeAttr? runtime_override_get_vcf_header_with_members_info_line
    RuntimeAttr? runtime_override_concat_shards

    # overrides for ResolveComplexContig
    RuntimeAttr? runtime_override_get_se_cutoff
    RuntimeAttr? runtime_override_shard_vcf_cpx
    RuntimeAttr? runtime_override_resolve_prep
    RuntimeAttr? runtime_override_resolve_cpx_per_shard
    RuntimeAttr? runtime_override_restore_unresolved_cnv_per_shard
    RuntimeAttr? runtime_override_concat_resolved_per_shard

    # overrides for GenotypeComplexContig
    RuntimeAttr? runtime_override_split_vcf_to_genotype
    RuntimeAttr? runtime_override_concat_cpx_cnv_vcfs
    RuntimeAttr? runtime_override_get_cpx_cnv_intervals
    RuntimeAttr? runtime_override_parse_genotypes
    RuntimeAttr? runtime_override_merge_melted_gts
    RuntimeAttr? runtime_override_split_bed_by_size
    RuntimeAttr? runtime_override_rd_genotype
    RuntimeAttr? runtime_override_concat_melted_genotypes

    # overrides for CleanVcfContig
    RuntimeAttr? runtime_override_clean_vcf_1a
    RuntimeAttr? runtime_override_clean_vcf_1b
    RuntimeAttr? runtime_override_clean_vcf_2
    RuntimeAttr? runtime_override_clean_vcf_3
    RuntimeAttr? runtime_override_clean_vcf_4
    RuntimeAttr? runtime_override_clean_vcf_5
    RuntimeAttr? runtime_override_drop_redundant_cnvs
    RuntimeAttr? runtime_override_stitch_fragmented_cnvs
    RuntimeAttr? runtime_override_final_cleanup
    RuntimeAttr? runtime_override_split_vcf_to_clean
    RuntimeAttr? runtime_override_combine_step_1_vcfs
    RuntimeAttr? runtime_override_combine_step_1_sex_chr_revisions
    RuntimeAttr? runtime_override_split_whitelist
    RuntimeAttr? runtime_override_combine_clean_vcf_2
    RuntimeAttr? runtime_override_combine_revised_4
    RuntimeAttr? runtime_override_combine_multi_ids_4

    # overrides for VcfQc
    RuntimeAttr? runtime_override_plot_qc_vcf_wide
    RuntimeAttr? runtime_override_thousand_g_benchmark
    RuntimeAttr? runtime_override_thousand_g_plot
    RuntimeAttr? runtime_override_asc_benchmark
    RuntimeAttr? runtime_override_asc_plot
    RuntimeAttr? runtime_override_hgsv_benchmark
    RuntimeAttr? runtime_override_hgsv_plot
    RuntimeAttr? runtime_override_plot_qc_per_sample
    RuntimeAttr? runtime_override_plot_qc_per_family
    RuntimeAttr? runtime_override_sanders_per_sample_plot
    RuntimeAttr? runtime_override_collins_per_sample_plot
    RuntimeAttr? runtime_override_werling_per_sample_plot
    RuntimeAttr? runtime_override_sanitize_outputs
    RuntimeAttr? runtime_override_merge_vcfwide_stat_shards
    RuntimeAttr? runtime_override_merge_vcf_2_bed
    RuntimeAttr? runtime_override_collect_sharded_vcf_stats
    RuntimeAttr? runtime_override_svtk_vcf_2_bed
    RuntimeAttr? runtime_override_split_vcf_to_qc
    RuntimeAttr? runtime_override_merge_subvcf_stat_shards
    RuntimeAttr? runtime_override_merge_svtk_vcf_2_bed
    RuntimeAttr? runtime_override_collect_vids_per_sample
    RuntimeAttr? runtime_override_split_samples_list
    RuntimeAttr? runtime_override_tar_shard_vid_lists
    RuntimeAttr? runtime_override_benchmark_samples
    RuntimeAttr? runtime_override_split_shuffled_list
    RuntimeAttr? runtime_override_merge_and_tar_shard_benchmarks
  }

  # Preprocess some inputs
  Int num_pass_lines=length(read_lines(raw_sr_bothside_pass))
  call MiniTasks.CatUncompressedFiles as CleanBothsidePass {
    input:
      shards=read_lines(raw_sr_bothside_pass),
      filter_command="sort | uniq -c | awk -v OFS='\\t' '{print $1/~{num_pass_lines}, $2}'",
      outfile_name="cohort_sr_genotyping_bothside_pass_list.txt",
      sv_base_mini_docker=sv_base_mini_docker,
      runtime_attr_override=runtime_override_clean_bothside_pass
  }
  File sr_bothend_pass = CleanBothsidePass.outfile

  Float min_background_fail_first_col = min_sr_background_fail_batches * length(read_lines(raw_sr_background_fail))
  call MiniTasks.CatUncompressedFiles as CleanBackgroundFail {
    input:
      shards=read_lines(raw_sr_background_fail),
      filter_command="sort | uniq -c | awk -v OFS='\\t' '{if($1 >= ~{min_background_fail_first_col}) print $2}'",
      outfile_name="cohort_sr_genotyping_background_fail_list.txt",
      sv_base_mini_docker=sv_base_mini_docker,
      runtime_attr_override=runtime_override_clean_background_fail
  }
  File sr_background_fail = CleanBackgroundFail.outfile

  call MiniTasks.CatUncompressedFiles as MergeFamFileList {
    input:
      shards=read_lines(fam_file_list),
      outfile_name="merged_famfile.fam",
      sv_base_mini_docker=sv_base_mini_docker,
      runtime_attr_override=runtime_override_merge_fam_file_list
  }
  File fam_file = MergeFamFileList.outfile

  #Prep input file for depth genotyping of complex intervals
  call MiniTasks.PasteFiles as MakeCpxCnvInputFile {
    input:
      input_files=[batches_list, bincov_list, bincov_idx_list,
                   depth_gt_rd_sep_list, sampleslist_list, fam_file_list,
                   medianfile_list],
      outfile_name=prefix + ".cpx_cnv_genotyping_input.txt",
      sv_base_mini_docker=sv_base_mini_docker,
      runtime_attr_override=runtime_override_make_cpx_cnv_input_file
  }

  # get size of discfiles
  call GetDiscfileSize {
    input:
      discfile_list=discfile_list,
      sv_pipeline_docker=sv_pipeline_docker,
      runtime_attr_override=runtime_overide_get_discfile_size
  }

  #Scatter per chromosome
  Array[String] contigs = transpose(read_tsv(contig_list))[0]
  scatter ( contig in contigs ) {

    #Subset PESR VCFs to single chromosome & cluster
    #Note: also subsets bothside_pass and background_fail files to variants 
    #present on chromosome of interest
    call VcfClusterContig.VcfClusterSingleChrom as ClusterPesr {
      input:
        vcf_list=pesr_vcf_list,
        batches_list=batches_list,
        prefix="AllBatches_pesr",
        dist=300,
        frac=0.1,
        sample_overlap=0.5,
        blacklist=pe_blacklist,
        blacklist_idx=pe_blacklist_idx,
        sv_size=50,
        sv_types=["DEL","DUP","INV","BND","INS"],
        contig=contig,
        max_shards_per_chrom_svtype=100,
        min_variants_per_shard_per_chrom_svtype=100,
        subset_sr_lists=true,
        bothside_pass=sr_bothend_pass,
        background_fail=sr_background_fail,
        sv_pipeline_docker=sv_pipeline_docker,
        sv_base_mini_docker=sv_base_mini_docker,
        runtime_override_join_vcfs=runtime_override_join_vcfs,
        runtime_override_subset_bothside_pass=runtime_override_subset_bothside_pass,
        runtime_override_subset_background_fail=runtime_override_subset_background_fail,
        runtime_override_subset_sv_type=runtime_override_subset_sv_type,
        runtime_override_concat_sv_types=runtime_override_concat_sv_types,
        runtime_override_shard_vcf_precluster=runtime_override_shard_vcf_precluster,
        runtime_override_svtk_vcf_cluster=runtime_override_svtk_vcf_cluster,
        runtime_override_get_vcf_header_with_members_info_line=runtime_override_get_vcf_header_with_members_info_line,
        runtime_override_concat_shards=runtime_override_concat_shards
    }

    #Subset RD VCFs to single chromosome & cluster
    call VcfClusterContig.VcfClusterSingleChrom as ClusterDepth {
      input:
        vcf_list=depth_vcf_list,
        batches_list=batches_list,
        prefix="AllBatches_depth",
        dist=500000,
        frac=0.5,
        sample_overlap=0.5,
        blacklist=depth_blacklist,
        blacklist_idx=depth_blacklist_idx,
        sv_size=5000,
        sv_types=["DEL","DUP"],
        contig=contig,
        max_shards_per_chrom_svtype=100,
        min_variants_per_shard_per_chrom_svtype=100,
        subset_sr_lists=false,
        bothside_pass=sr_bothend_pass,
        background_fail=sr_background_fail,
        sv_pipeline_docker=sv_pipeline_docker,
        sv_base_mini_docker=sv_base_mini_docker,
        runtime_override_join_vcfs=runtime_override_join_vcfs,
        runtime_override_subset_bothside_pass=runtime_override_subset_bothside_pass,
        runtime_override_subset_background_fail=runtime_override_subset_background_fail,
        runtime_override_subset_sv_type=runtime_override_subset_sv_type,
        runtime_override_concat_sv_types=runtime_override_concat_sv_types,
        runtime_override_shard_vcf_precluster=runtime_override_shard_vcf_precluster,
        runtime_override_svtk_vcf_cluster=runtime_override_svtk_vcf_cluster,
        runtime_override_get_vcf_header_with_members_info_line=runtime_override_get_vcf_header_with_members_info_line,
        runtime_override_concat_shards=runtime_override_concat_shards
    }

    #Update SR background fail & bothside pass files (1)
    call UpdateSrList as UpdateBackgroundFailFirst {
      input:
        vcf=ClusterPesr.clustered_vcf,
        original_list=ClusterPesr.filtered_background_fail,
        outfile="sr_background_fail.~{contig}.updated.txt",
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_update_sr_list
    }
    call UpdateSrList as UpdateBothsidePassFirst {
      input:
        vcf=ClusterPesr.clustered_vcf,
        original_list=ClusterPesr.filtered_bothside_pass,
        outfile="sr_bothside_pass.~{contig}.updated.txt",
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_update_sr_list
    }

    #Merge PESR & RD VCFs
    call MergePesrDepth {
      input:
        pesr_vcf=ClusterPesr.clustered_vcf,
        depth_vcf=ClusterDepth.clustered_vcf,
        contig=contig,
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_merge_pesr_depth

    }

    #Update SR background fail & bothside pass files (2)
    call UpdateSrList as UpdateBackgroundFailSecond {
      input:
        vcf=MergePesrDepth.merged_vcf,
        original_list=UpdateBackgroundFailFirst.updated_list,
        outfile="sr_background_fail.~{contig}.updated2.txt",
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_update_sr_list

    }
    call UpdateSrList as UpdateBothsidePassSecond {
      input:
        vcf=MergePesrDepth.merged_vcf,
        original_list=UpdateBothsidePassFirst.updated_list,
        outfile="sr_bothside_pass.~{contig}.updated2.txt",
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_update_sr_list
    }

    #Subset inversions from PESR+RD VCF
    call MiniTasks.FilterVcf as SubsetInversions {
      input:
        vcf=MergePesrDepth.merged_vcf,
        outfile_prefix="~{prefix}.~{contig}.inversions_only",
        records_filter="fgrep SVTYPE=INV",
        sv_base_mini_docker=sv_base_mini_docker,
        runtime_attr_override=runtime_override_subset_inversions
    }

    #Resolve inversion-only VCF
    call ResolveComplexContig.ResolveComplexSv as ResolveCpxInv {
      input:
        vcf=SubsetInversions.filtered_vcf,
        vcf_idx=SubsetInversions.filtered_vcf_idx,
        prefix="~{prefix}.inv_only",
        contig=contig,
        max_shards_per_chrom=max_shards_per_chrom,
        min_variants_per_shard=100,
        cytobands=cytobands,
        cytobands_idx=cytobands_idx,
        discfile_list=discfile_list,
        discfile_idx_list=discfile_idx_list,
        discfile_size_gb=GetDiscfileSize.discfile_size_gb,
        mei_bed=mei_bed,
        pe_blacklist=pe_blacklist,
        pe_blacklist_idx=pe_blacklist_idx,
        rf_cutoffs=rf_cutoffs,
        inv_only=true,
        sv_pipeline_docker=sv_pipeline_docker,
        sv_base_mini_docker=sv_base_mini_docker,
        runtime_override_get_se_cutoff=runtime_override_get_se_cutoff,
        runtime_override_shard_vcf_cpx=runtime_override_shard_vcf_cpx,
        runtime_override_resolve_prep=runtime_override_resolve_prep,
        runtime_override_resolve_cpx_per_shard=runtime_override_resolve_cpx_per_shard,
        runtime_override_restore_unresolved_cnv_per_shard=runtime_override_restore_unresolved_cnv_per_shard,
        runtime_override_concat_resolved_per_shard=runtime_override_concat_resolved_per_shard
    }

    #Run same-bp overlap filter on full vcf
    call BreakpointOverlapFilter {
      input:
        vcf=MergePesrDepth.merged_vcf,
        prefix="~{prefix}.~{contig}",
        bothside_pass=UpdateBothsidePassSecond.updated_list,
        background_fail=UpdateBackgroundFailSecond.updated_list,
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_breakpoint_overlap_filter
    }

    #Resolve all-variants VCF after same-bp overlap filter
    call ResolveComplexContig.ResolveComplexSv as ResolveCpxAll {
      input:
        vcf=BreakpointOverlapFilter.bp_filtered_vcf,
        vcf_idx=BreakpointOverlapFilter.bp_filtered_vcf_idx,
        prefix="~{prefix}.all_variants",
        contig=contig,
        max_shards_per_chrom=max_shards_per_chrom,
        min_variants_per_shard=100,
        cytobands=cytobands,
        cytobands_idx=cytobands_idx,
        discfile_list=discfile_list,
        discfile_idx_list=discfile_idx_list,
        discfile_size_gb=GetDiscfileSize.discfile_size_gb,
        mei_bed=mei_bed,
        pe_blacklist=pe_blacklist,
        pe_blacklist_idx=pe_blacklist_idx,
        rf_cutoffs=rf_cutoffs,
        inv_only=false,
        sv_pipeline_docker=sv_pipeline_docker,
        sv_base_mini_docker=sv_base_mini_docker,
        runtime_override_get_se_cutoff=runtime_override_get_se_cutoff,
        runtime_override_shard_vcf_cpx=runtime_override_shard_vcf_cpx,
        runtime_override_resolve_prep=runtime_override_resolve_prep,
        runtime_override_resolve_cpx_per_shard=runtime_override_resolve_cpx_per_shard,
        runtime_override_restore_unresolved_cnv_per_shard=runtime_override_restore_unresolved_cnv_per_shard,
        runtime_override_concat_resolved_per_shard=runtime_override_concat_resolved_per_shard
    }

    #Integrate inv-only and all-variants resolved VCFs
    call IntegrateResolvedVcfs {
      input:
        inv_res_vcf=ResolveCpxInv.resolved_vcf_merged,
        all_res_vcf=ResolveCpxAll.resolved_vcf_merged,
        prefix="~{prefix}.resolved.~{contig}",
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_integrate_resolved_vcfs
    }

    #Apply consistent variant naming scheme to integrated VCF
    call RenameVariants {
      input:
        vcf=IntegrateResolvedVcfs.integrated_vcf,
        prefix="~{prefix}.~{contig}",
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_rename_variants
    }
    
    #Update SR background fail & bothside pass files
    call UpdateSrList as UpdateBackgroundFailThird {
      input:
        vcf=RenameVariants.renamed_vcf,
        original_list=UpdateBackgroundFailSecond.updated_list,
        outfile="sr_background_fail.~{contig}.updated3.txt",
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_attr_override=runtime_override_update_sr_list
    }

    #Depth-based genotyping of complex intervals
    call GenotypeComplexContig.ScatterCpxGenotyping as ScatterContigCpxGenotyping {
      input:
        vcf=RenameVariants.renamed_vcf,
        n_master_vcf_shards=200,
        n_master_min_vars_per_vcf_shard=5000,
        gt_input_files=MakeCpxCnvInputFile.outfile,
        n_per_split_small=2500,
        n_per_split_large=250,
        n_rd_test_bins=100000,
        prefix=prefix,
        contig=contig,
        fam_file=fam_file,
        sv_base_mini_docker=sv_base_mini_docker,
        sv_pipeline_docker=sv_pipeline_docker,
        sv_pipeline_rdtest_docker=sv_pipeline_rdtest_docker,
        runtime_override_split_vcf_to_genotype=runtime_override_split_vcf_to_genotype,
        runtime_override_concat_cpx_cnv_vcfs=runtime_override_concat_cpx_cnv_vcfs,
        runtime_override_get_cpx_cnv_intervals=runtime_override_get_cpx_cnv_intervals,
        runtime_override_parse_genotypes=runtime_override_parse_genotypes,
        runtime_override_merge_melted_gts=runtime_override_merge_melted_gts,
        runtime_override_split_bed_by_size=runtime_override_split_bed_by_size,
        runtime_override_rd_genotype=runtime_override_rd_genotype,
        runtime_override_concat_melted_genotypes=runtime_override_concat_melted_genotypes
    }

    #CleanVcf (module 05)
    call CleanVcfContig.CleanVcf as CleanContigVcf {
      input:
        vcf=ScatterContigCpxGenotyping.cpx_depth_gt_resolved_vcf,
        contig=contig,
        background_list=UpdateBackgroundFailThird.updated_list,
        fam_file=fam_file,
        prefix=prefix,
        max_shards_per_chrom_step1=max_shards_per_chrom_clean_vcf_step1,
        min_records_per_shard_step1=min_records_per_shard_clean_vcf_step1,
        samples_per_step2_shard=samples_per_clean_vcf_step2_shard,
        outlier_samples_list=outlier_samples_list,
        sv_base_mini_docker=sv_base_mini_docker,
        sv_pipeline_docker=sv_pipeline_docker,
        runtime_override_clean_vcf_1a=runtime_override_clean_vcf_1a,
        runtime_override_clean_vcf_1b=runtime_override_clean_vcf_1b,
        runtime_override_clean_vcf_2=runtime_override_clean_vcf_2,
        runtime_override_clean_vcf_3=runtime_override_clean_vcf_3,
        runtime_override_clean_vcf_4=runtime_override_clean_vcf_4,
        runtime_override_clean_vcf_5=runtime_override_clean_vcf_5,
        runtime_override_drop_redundant_cnvs=runtime_override_drop_redundant_cnvs,
        runtime_override_stitch_fragmented_cnvs=runtime_override_stitch_fragmented_cnvs,
        runtime_override_final_cleanup=runtime_override_final_cleanup,
        runtime_override_split_vcf_to_clean=runtime_override_split_vcf_to_clean,
        runtime_override_combine_step_1_vcfs=runtime_override_combine_step_1_vcfs,
        runtime_override_combine_step_1_sex_chr_revisions=runtime_override_combine_step_1_sex_chr_revisions,
        runtime_override_split_whitelist=runtime_override_split_whitelist,
        runtime_override_combine_clean_vcf_2=runtime_override_combine_clean_vcf_2,
        runtime_override_combine_revised_4=runtime_override_combine_revised_4,
        runtime_override_combine_multi_ids_4=runtime_override_combine_multi_ids_4
    }
  }

  #Merge PESR+RD VCFs for 04b midpoint QC
  call MiniTasks.ConcatVcfs as ConcatMidpointVcfs {
    input:
      vcfs=MergePesrDepth.merged_vcf,
      outfile_prefix="~{prefix}.pesr_rd_merged",
      sv_base_mini_docker=sv_base_mini_docker,
      runtime_attr_override=runtime_override_concat_midpoint_vcfs
  }

  #Run midpoint QC on merged PESR+RD VCF across all chromosomes
  call VcfQc.MasterVcfQc as MidpointQc {
    input:
      vcf=ConcatMidpointVcfs.concat_vcf,
      vcf_idx=ConcatMidpointVcfs.concat_vcf_idx,
      fam_file=trios_fam_file,
      prefix="~{prefix}_pesr_rd_merged_VCF",
      sv_per_shard=10000,
      samples_per_shard=100,
      sanders_2015_tarball=sanders_2015_tarball,
      collins_2017_tarball=collins_2017_tarball,
      werling_2018_tarball=werling_2018_tarball,
      contigs=contigs,
      random_seed=random_seed,
      include_external_benchmarking=include_external_benchmarking,
      sv_pipeline_qc_docker=sv_pipeline_qc_docker,
      sv_base_mini_docker=sv_base_mini_docker,
      sv_pipeline_docker=sv_pipeline_docker,
      runtime_override_plot_qc_vcf_wide=runtime_override_plot_qc_vcf_wide,
      runtime_override_thousand_g_benchmark=runtime_override_thousand_g_benchmark,
      runtime_override_thousand_g_plot=runtime_override_thousand_g_plot,
      runtime_override_asc_benchmark=runtime_override_asc_benchmark,
      runtime_override_asc_plot=runtime_override_asc_plot,
      runtime_override_hgsv_benchmark=runtime_override_hgsv_benchmark,
      runtime_override_hgsv_plot=runtime_override_hgsv_plot,
      runtime_override_plot_qc_per_sample=runtime_override_plot_qc_per_sample,
      runtime_override_plot_qc_per_family=runtime_override_plot_qc_per_family,
      runtime_override_sanders_per_sample_plot=runtime_override_sanders_per_sample_plot,
      runtime_override_collins_per_sample_plot=runtime_override_collins_per_sample_plot,
      runtime_override_werling_per_sample_plot=runtime_override_werling_per_sample_plot,
      runtime_override_sanitize_outputs=runtime_override_sanitize_outputs,
      runtime_override_merge_vcfwide_stat_shards=runtime_override_merge_vcfwide_stat_shards,
      runtime_override_merge_vcf_2_bed=runtime_override_merge_vcf_2_bed,
      runtime_override_collect_sharded_vcf_stats=runtime_override_collect_sharded_vcf_stats,
      runtime_override_svtk_vcf_2_bed=runtime_override_svtk_vcf_2_bed,
      runtime_override_split_vcf_to_qc=runtime_override_split_vcf_to_qc,
      runtime_override_merge_subvcf_stat_shards=runtime_override_merge_subvcf_stat_shards,
      runtime_override_merge_svtk_vcf_2_bed=runtime_override_merge_svtk_vcf_2_bed,
      runtime_override_collect_vids_per_sample=runtime_override_collect_vids_per_sample,
      runtime_override_split_samples_list=runtime_override_split_samples_list,
      runtime_override_tar_shard_vid_lists=runtime_override_tar_shard_vid_lists,
      runtime_override_benchmark_samples=runtime_override_benchmark_samples,
      runtime_override_split_shuffled_list=runtime_override_split_shuffled_list,
      runtime_override_merge_and_tar_shard_benchmarks=runtime_override_merge_and_tar_shard_benchmarks
  }

  #Merge final resolved vcfs for 04b final QC
  call MiniTasks.ConcatVcfs as ConcatFinalVcfs {
    input:
      vcfs=ScatterContigCpxGenotyping.cpx_depth_gt_resolved_vcf,
      outfile_prefix="~{prefix}.resolved_regenotyped",
      sv_base_mini_docker=sv_base_mini_docker,
      runtime_attr_override=runtime_override_concat_final_vcfs

  }

  #Run final QC on resolved VCF across all chromosomes
  call VcfQc.MasterVcfQc as FinalQc {
    input:
      vcf=ConcatFinalVcfs.concat_vcf,
      vcf_idx=ConcatFinalVcfs.concat_vcf_idx,
      fam_file=trios_fam_file,
      prefix="~{prefix}_resolved_VCF",
      sv_per_shard=10000,
      samples_per_shard=100,
      sanders_2015_tarball=sanders_2015_tarball,
      collins_2017_tarball=collins_2017_tarball,
      werling_2018_tarball=werling_2018_tarball,
      contigs=contigs,
      random_seed=random_seed,
      include_external_benchmarking=include_external_benchmarking,
      sv_pipeline_qc_docker=sv_pipeline_qc_docker,
      sv_base_mini_docker=sv_base_mini_docker,
      sv_pipeline_docker=sv_pipeline_docker,
  }

  #Merge final cleaned vcfs for 05 final QC
  call MiniTasks.ConcatVcfs as ConcatCleanedVcfs {
    input:
      vcfs=CleanContigVcf.out,
      outfile_prefix="~{prefix}.cleaned",
      sv_base_mini_docker=sv_base_mini_docker,
      runtime_attr_override=runtime_override_concat_cleaned_vcfs
  }

  #Run final QC on cleaned VCF across all chromosomes
  call VcfQc.MasterVcfQc as QcCleanedVcf {
    input:
      vcf=ConcatCleanedVcfs.concat_vcf,
      vcf_idx=ConcatCleanedVcfs.concat_vcf_idx,
      fam_file=trios_fam_file,
      prefix="~{prefix}_cleaned_VCF",
      sv_per_shard=10000,
      samples_per_shard=100,
      sanders_2015_tarball=sanders_2015_tarball,
      collins_2017_tarball=collins_2017_tarball,
      werling_2018_tarball=werling_2018_tarball,
      contigs=contigs,
      random_seed=random_seed,
      include_external_benchmarking=include_external_benchmarking,
      sv_pipeline_qc_docker=sv_pipeline_qc_docker,
      sv_base_mini_docker=sv_base_mini_docker,
      sv_pipeline_docker=sv_pipeline_docker,
  }

  #Final outputs
  output {
    File final_04b_vcf = ConcatFinalVcfs.concat_vcf
    File final_04b_vcf_idx = ConcatFinalVcfs.concat_vcf_idx
    File midpoint_04b_vcf_qc = MidpointQc.sv_vcf_qc_output
    File final_04b_vcf_qc = FinalQc.sv_vcf_qc_output
    File cleaned_vcf = ConcatCleanedVcfs.concat_vcf
    File cleaned_vcf_idx = ConcatCleanedVcfs.concat_vcf_idx
    File cleaned_vcf_qc = QcCleanedVcf.sv_vcf_qc_output
  }
}


task GetDiscfileSize {
  input {
    File discfile_list
    String sv_pipeline_docker
    RuntimeAttr? runtime_attr_override
  }

  String discfile_size_file_name = "discfile_size.txt"

  Float input_size = size(discfile_list, "GiB")
  Float base_disk_gb = 5.0
  Float base_mem_gb = 2.0
  RuntimeAttr runtime_default = object {
    mem_gb: base_mem_gb,
    disk_gb: ceil(base_disk_gb + input_size),
    cpu_cores: 1,
    preemptible_tries: 3,
    max_retries: 1,
    boot_disk_gb: 10
  }
  RuntimeAttr runtime_override = select_first([runtime_attr_override, runtime_default])
  runtime {
    memory: "~{select_first([runtime_override.mem_gb, runtime_default.mem_gb])} GiB"
    disks: "local-disk ~{select_first([runtime_override.disk_gb, runtime_default.disk_gb])} HDD"
    cpu: select_first([runtime_override.cpu_cores, runtime_default.cpu_cores])
    preemptible: select_first([runtime_override.preemptible_tries, runtime_default.preemptible_tries])
    maxRetries: select_first([runtime_override.max_retries, runtime_default.max_retries])
    docker : sv_pipeline_docker
    bootDiskSizeGb: select_first([runtime_override.boot_disk_gb, runtime_default.boot_disk_gb])
  }

  command <<<
    set -eu -o pipefail
    export GCS_OAUTH_TOKEN=`gcloud auth application-default print-access-token`

    # shouldn't be many discfiles, so join them on one line and save the overhead of multiple gsutil calls
    gsutil du -c $(tr -s $'\n' ' ' < ~{discfile_list}) \
      | awk 'END {print $1 / 2^30}' \
      > ~{discfile_size_file_name}
  >>>

  output {
    File discfile_size_file = discfile_size_file_name
    Float discfile_size_gb = read_float(discfile_size_file)
  }
}


#Update either SR bothside_pass or background_fail files
task UpdateSrList {
  input {
    File vcf
    File original_list
    String outfile
    String sv_pipeline_docker
    RuntimeAttr? runtime_attr_override
  }

  # when filtering/sorting/etc, memory usage will likely go up (much of the data will have to
  # be held in memory or disk while working, potentially in a form that takes up more space)
  Float input_size = size([vcf, original_list], "GiB")
  Float compression_factor = 5.0
  Float base_disk_gb = 5.0
  Float base_mem_gb = 2.0
  RuntimeAttr runtime_default = object {
    mem_gb: base_mem_gb + compression_factor * input_size,
    disk_gb: ceil(base_disk_gb + input_size * (2.0 + 2.0 * compression_factor)),
    cpu_cores: 1,
    preemptible_tries: 3,
    max_retries: 1,
    boot_disk_gb: 10
  }
  RuntimeAttr runtime_override = select_first([runtime_attr_override, runtime_default])
  runtime {
    memory: "~{select_first([runtime_override.mem_gb, runtime_default.mem_gb])} GiB"
    disks: "local-disk ~{select_first([runtime_override.disk_gb, runtime_default.disk_gb])} HDD"
    cpu: select_first([runtime_override.cpu_cores, runtime_default.cpu_cores])
    preemptible: select_first([runtime_override.preemptible_tries, runtime_default.preemptible_tries])
    maxRetries: select_first([runtime_override.max_retries, runtime_default.max_retries])
    docker: sv_pipeline_docker
    bootDiskSizeGb: select_first([runtime_override.boot_disk_gb, runtime_default.boot_disk_gb])
  }

  command <<<
    set -eu -o pipefail
  
    /opt/sv-pipeline/04_variant_resolution/scripts/trackpesr_ID.sh \
      ~{vcf} \
      ~{original_list} \
      ~{outfile}
  >>>

  output {
    File updated_list = outfile
  }
}


#Merge PESR + RD VCFs
task MergePesrDepth {
  input {
    File pesr_vcf
    File depth_vcf
    String contig
    String sv_pipeline_docker
    RuntimeAttr? runtime_attr_override
  }

  String output_file = "all_batches.pesr_depth.~{contig}.vcf.gz"

  # when filtering/sorting/etc, memory usage will likely go up (much of the data will have to
  # be held in memory or disk while working, potentially in a form that takes up more space)
  Float input_size = size([pesr_vcf, depth_vcf], "GiB")
  Float compression_factor = 5.0
  Float base_disk_gb = 5.0
  Float base_mem_gb = 2.0
  RuntimeAttr runtime_default = object {
    mem_gb: base_mem_gb + compression_factor * input_size,
    disk_gb: ceil(base_disk_gb + input_size * (2.0 + 3.0 * compression_factor)),
    cpu_cores: 1,
    preemptible_tries: 3,
    max_retries: 1,
    boot_disk_gb: 10
  }
  RuntimeAttr runtime_override = select_first([runtime_attr_override, runtime_default])
  runtime {
    memory: "~{select_first([runtime_override.mem_gb, runtime_default.mem_gb])} GiB"
    disks: "local-disk ~{select_first([runtime_override.disk_gb, runtime_default.disk_gb])} HDD"
    cpu: select_first([runtime_override.cpu_cores, runtime_default.cpu_cores])
    preemptible: select_first([runtime_override.preemptible_tries, runtime_default.preemptible_tries])
    maxRetries: select_first([runtime_override.max_retries, runtime_default.max_retries])
    docker: sv_pipeline_docker
    bootDiskSizeGb: select_first([runtime_override.boot_disk_gb, runtime_default.boot_disk_gb])
  }

  command <<<
    set -eu -o pipefail
    
    /opt/sv-pipeline/04_variant_resolution/scripts/PESR_RD_merge_wrapper.sh \
      ~{pesr_vcf} \
      ~{depth_vcf} \
      ~{contig} \
      ~{output_file}
    
    tabix -p vcf -f ~{output_file}
  >>>

  output {
    File merged_vcf = output_file
    File merged_vcf_idx = output_file + ".tbi"
  }
}

#Run Harrison's overlapping breakpoint filter prior to complex resolution
task BreakpointOverlapFilter {
  input {
    File vcf
    String prefix
    File bothside_pass
    File background_fail
    String sv_pipeline_docker
    RuntimeAttr? runtime_attr_override
  }

  String temp_output_file = "non_redundant.vcf.gz"
  String output_file = prefix + "." + temp_output_file

  Float input_size = size([vcf, bothside_pass, background_fail], "GiB")
  Float base_mem_gb = 2.0
  Float base_disk_gb = 5.0
  RuntimeAttr runtime_default = object {
    mem_gb: base_mem_gb,
    disk_gb: ceil(base_disk_gb + input_size * 3.0),
    cpu_cores: 1,
    preemptible_tries: 3,
    max_retries: 1,
    boot_disk_gb: 10
  }
  RuntimeAttr runtime_override = select_first([runtime_attr_override, runtime_default])
  runtime {
    memory: "~{select_first([runtime_override.mem_gb, runtime_default.mem_gb])} GiB"
    disks: "local-disk ~{select_first([runtime_override.disk_gb, runtime_default.disk_gb])} HDD"
    cpu: select_first([runtime_override.cpu_cores, runtime_default.cpu_cores])
    preemptible: select_first([runtime_override.preemptible_tries, runtime_default.preemptible_tries])
    maxRetries: select_first([runtime_override.max_retries, runtime_default.max_retries])
    docker: sv_pipeline_docker
    bootDiskSizeGb: select_first([runtime_override.boot_disk_gb, runtime_default.boot_disk_gb])
  }

  command <<<
    set -eu -o pipefail
    
    /opt/sv-pipeline/04_variant_resolution/scripts/overlapbpchange.sh \
      ~{vcf} \
      ~{background_fail} \
      ~{bothside_pass}
      
    mv "~{temp_output_file}" "~{output_file}"
    tabix -p vcf -f "~{output_file}"
  >>>

  output {
    File bp_filtered_vcf = output_file
    File bp_filtered_vcf_idx = output_file + ".tbi"
  }
}


#Merge inversion-only and all-variant cpx-resolved outputs
task IntegrateResolvedVcfs {
  input {
    File inv_res_vcf
    File all_res_vcf
    String prefix
    String sv_pipeline_docker
    RuntimeAttr? runtime_attr_override
  }

  Float input_size = size([inv_res_vcf, all_res_vcf], "GiB")
  Float base_mem_gb = 2.0
  Float base_disk_gb = 5.0
  RuntimeAttr runtime_default = object {
    mem_gb: base_mem_gb,
    disk_gb: ceil(base_disk_gb + input_size * 3.0),
    cpu_cores: 1,
    preemptible_tries: 3,
    max_retries: 1,
    boot_disk_gb: 10
  }
  RuntimeAttr runtime_override = select_first([runtime_attr_override, runtime_default])
  runtime {
    memory: "~{select_first([runtime_override.mem_gb, runtime_default.mem_gb])} GiB"
    disks: "local-disk ~{select_first([runtime_override.disk_gb, runtime_default.disk_gb])} HDD"
    cpu: select_first([runtime_override.cpu_cores, runtime_default.cpu_cores])
    preemptible: select_first([runtime_override.preemptible_tries, runtime_default.preemptible_tries])
    maxRetries: select_first([runtime_override.max_retries, runtime_default.max_retries])
    docker: sv_pipeline_docker
    bootDiskSizeGb: select_first([runtime_override.boot_disk_gb, runtime_default.boot_disk_gb])
  }

  command <<<
    set -eu -o pipefail
    
    /opt/sv-pipeline/04_variant_resolution/scripts/Complex_Inversion_Integration.sh \
      ~{inv_res_vcf} \
      ~{all_res_vcf} \
      ~{prefix}.integrated_resolved.vcf.gz
      
    tabix -p vcf -f "~{prefix}.integrated_resolved.vcf.gz"
  >>>

  output {
    File integrated_vcf = "~{prefix}.integrated_resolved.vcf.gz"
    File integrated_vcf_idx = "~{prefix}.integrated_resolved.vcf.gz.tbi"
  }
}


# Rename variants in VCF
task RenameVariants {
  input {
    File vcf
    String prefix
    String sv_pipeline_docker
    RuntimeAttr? runtime_attr_override
  }

  Float input_size = size(vcf, "GiB")
  Float base_mem_gb = 2.0
  Float base_disk_gb = 5.0
  RuntimeAttr runtime_default = object {
    mem_gb: base_mem_gb,
    disk_gb: ceil(base_disk_gb + input_size * 2.0),
    cpu_cores: 1,
    preemptible_tries: 3,
    max_retries: 1,
    boot_disk_gb: 10
  }
  RuntimeAttr runtime_override = select_first([runtime_attr_override, runtime_default])
  runtime {
    memory: "~{select_first([runtime_override.mem_gb, runtime_default.mem_gb])} GiB"
    disks: "local-disk ~{select_first([runtime_override.disk_gb, runtime_default.disk_gb])} HDD"
    cpu: select_first([runtime_override.cpu_cores, runtime_default.cpu_cores])
    preemptible: select_first([runtime_override.preemptible_tries, runtime_default.preemptible_tries])
    maxRetries: select_first([runtime_override.max_retries, runtime_default.max_retries])
    docker: sv_pipeline_docker
    bootDiskSizeGb: select_first([runtime_override.boot_disk_gb, runtime_default.boot_disk_gb])
  }

  command <<<
    set -eu -o pipefail
    
    /opt/sv-pipeline/04_variant_resolution/scripts/rename.py \
      --prefix ~{prefix} ~{vcf} - \
      | bgzip -c > "~{prefix}.04_renamed.vcf.gz"
  >>>

  output {
    File renamed_vcf = "~{prefix}.04_renamed.vcf.gz"
  }
}
