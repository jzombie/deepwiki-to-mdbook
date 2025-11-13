def test_normalized_number_parts_overview(scraper_module):
    assert scraper_module.normalized_number_parts("1") == []


def test_normalized_number_parts_main(scraper_module):
    assert scraper_module.normalized_number_parts("2") == ["1"]
    assert scraper_module.normalized_number_parts("4") == ["3"]


def test_normalized_number_parts_subsections(scraper_module):
    assert scraper_module.normalized_number_parts("4.2") == ["3", "2"]
    assert scraper_module.normalized_number_parts("1.3") == ["1", "3"]


def test_resolve_output_path_overview(scraper_module):
    filename, section = scraper_module.resolve_output_path("1", "Overview Title")
    assert filename == "overview-title.md"
    assert section is None


def test_resolve_output_path_main(scraper_module):
    filename, section = scraper_module.resolve_output_path("3", "System Architecture")
    assert filename == "2-system-architecture.md"
    assert section is None


def test_resolve_output_path_subsection(scraper_module):
    filename, section = scraper_module.resolve_output_path("5.2", "HTML to Markdown Conversion")
    assert filename == "4-2-html-to-markdown-conversion.md"
    assert section == "section-4"


def test_build_target_path_overview(scraper_module):
    assert scraper_module.build_target_path("1", "Overview Title") == "overview-title.md"


def test_build_target_path_main(scraper_module):
    assert (
        scraper_module.build_target_path("3", "System Architecture")
        == "2-system-architecture.md"
    )


def test_build_target_path_subsection(scraper_module):
    assert (
        scraper_module.build_target_path("6.2", "Diagram Extraction")
        == "section-5/5-2-diagram-extraction.md"
    )
