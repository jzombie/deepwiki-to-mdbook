def test_normalize_statement_separators_inserts_newline(scraper_module):
    diagram = "graph TD\n    A-->B B-->C\n"
    normalized = scraper_module.normalize_statement_separators(diagram)
    cleaned = [line.strip() for line in normalized.splitlines() if line.strip()]
    assert cleaned[1] == "A-->B"
    assert cleaned[2] == "B-->C"


def test_normalize_statement_separators_preserves_indentation(scraper_module):
    diagram = "graph TD\n    A-->B    B-->C\n"
    normalized = scraper_module.normalize_statement_separators(diagram)
    lines = [line for line in normalized.splitlines() if line.strip()]
    assert lines[1].lstrip().startswith("A-->B")
    assert len(lines[1]) - len(lines[1].lstrip()) >= 3
    assert lines[2].lstrip().startswith("B-->C")
    assert len(lines[2]) - len(lines[2].lstrip()) >= 3


def test_normalize_empty_node_labels(scraper_module):
    diagram = 'graph TD\n    Dead[""] --> Alive[""]\n'
    normalized = scraper_module.normalize_empty_node_labels(diagram)
    assert 'Dead["Dead"]' in normalized
    assert 'Alive["Alive"]' in normalized


def test_normalize_flowchart_nodes_strips_pipes(scraper_module):
    diagram = 'graph TD\n    A["Label | With Pipes"] --> B\n'
    normalized = scraper_module.normalize_flowchart_nodes(diagram)
    assert 'Label / With Pipes' in normalized


def test_normalize_mermaid_diagram_end_to_end(scraper_module):
    diagram = """graph TD
    Stage1[""] --> Stage2["Stage 2"]
    Stage2 --> Stage3 Stage3 --> Stage4
    """
    normalized = scraper_module.normalize_mermaid_diagram(diagram)
    assert 'Stage1["Stage1"]' in normalized
    lines = [line.strip() for line in normalized.splitlines() if line.strip()]
    assert "Stage2 --> Stage3" in lines
    assert "Stage3 --> Stage4" in lines
