{ lib
, fetchFromGitHub
, python3Packages
, runtimeShell
, bcftools
, htslib
}:

let
  ssshtest = fetchFromGitHub {
    owner = "ryanlayer";
    repo = "ssshtest";
    rev = "d21f7f928a167fca6e2eb31616673444d15e6fd0";
    hash = "sha256-zecZHEnfhDtT44VMbHLHOhRtNsIMWeaBASupVXtmrks=";
  };
in python3Packages.buildPythonApplication rec {
  pname = "truvari";
  version = "4.0.0";

  src = fetchFromGitHub {
    owner = "ACEnglish";
    repo = "truvari";
    rev = "v${version}";
    hash = "sha256-UJNMKEV5m2jFqnWvkVAtymkcE2TjPIXp7JqRZpMSqsE=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace "rich==" "rich>="
    substituteInPlace truvari/utils.py \
      --replace "/bin/bash" "${runtimeShell}"
    patchShebangs repo_utils/test_files
  '';

  propagatedBuildInputs = with python3Packages; [
    rich
    edlib
    pysam
    intervaltree
    joblib
    numpy
    pytabix
    bwapy
    pandas
  ];

  makeWrapperArgs = [
    "--prefix" "PATH" ":" (lib.makeBinPath [ bcftools htslib ])
  ];

  pythonImportsCheck = [ "truvari" ];

  nativeCheckInputs = [
    bcftools
    htslib
  ] ++ (with python3Packages; [
    coverage
  ]);

  checkPhase = ''
    runHook preCheck

    ln -s ${ssshtest}/ssshtest .
    bash repo_utils/truvari_ssshtests.sh

    runHook postCheck
  '';

  meta = with lib; {
    description = "Structural variant comparison tool for VCFs";
    homepage = "https://github.com/ACEnglish/truvari";
    license = licenses.mit;
    maintainers = with maintainers; [ natsukium scalavision ];
    longDescription = ''
      Truvari is a benchmarking tool for comparison sets of SVs.
      It can calculate the recall, precision, and f-measure of a
      vcf from a given structural variant caller. The tool
      is created by Spiral Genetics.
    '';
  };
}
