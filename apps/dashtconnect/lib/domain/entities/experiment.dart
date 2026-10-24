class Experiment {
  const Experiment(
    this.id,
    this.title,
    this.question,
    this.prerequisite,
    this.steps,
    this.supports,
    this.refutes,
    this.next,
  );

  final String id,
      title,
      question,
      prerequisite,
      steps,
      supports,
      refutes,
      next;
}
