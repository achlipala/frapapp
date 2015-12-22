open Bootstrap3
structure Theme = Ui.Make(Style)

table user : { MitId : string, UserName : string, IsInstructor : bool, IsTA : bool, IsStudent : bool, HasDropped : bool }
  PRIMARY KEY MitId,
  CONSTRAINT UserName UNIQUE UserName

(* Bootstrap the database with an initial admin user. *)
task initialize = fn () =>
  anyUsers <- oneRowE1 (SELECT COUNT( * ) > 0
                        FROM user);
  if anyUsers then
      return ()
  else
      dml (INSERT INTO user(MitId, UserName, IsInstructor, IsTA, IsStudent, HasDropped)
           VALUES ('adamc', 'Adam Chlipala', TRUE, FALSE, FALSE, FALSE))

structure Auth = MitCert.Make(struct
                                  con kerberos = #MitId
                                  con commonName = #UserName
                                  con groups = [IsInstructor, IsTA, IsStudent, HasDropped]
                                  val users = user
                                  val defaults = Some {IsInstructor = False,
                                                       IsTA = False,
                                                       IsStudent = False,
                                                       HasDropped = False}
                                  val allowMasquerade = None
                                  val requireSsl = True
                              end)

val gInstructor = make [#IsInstructor] ()
val amInstructor = Auth.inGroup gInstructor
val requireInstructor = Auth.requireGroup gInstructor

structure Sm = LinearStateMachine.Make(struct
                                           con steps = [BeforeSemester,
                                                        PollingAboutOfficeHours,
                                                        SteadyState,
                                                        AssigningFinalGrades,
                                                        SemesterOver]
                                           val mayChange = amInstructor
                                       end)

val courseInfo =
    Ui.const <xml>
      <div class="jumbotron">
        <div class="container">
          <h1>Formal Reasoning About Programs</h1>

          <p>A graduate course at MIT in Spring 2016</p>
        </div>
      </div>

      <table class="bs3-table table-striped">
        <tr> <th>Subject number:</th> <td>6.887</td> </tr>
        <tr> <th>Instructor:</th> <td><a href="http://adam.chlipala.net/">Adam Chlipala</a></td> </tr>
        <tr> <th>Teaching assistant:</th> <td><a href="http://people.csail.mit.edu/wangpeng/">Peng Wang</a></td> </tr>
        <tr> <th>Class meets:</th> <td>MW 2:30-4:00, 34-304</td> </tr>
      </table>

      <h2>What's it all about?</h2>

      <p><i>Briefly</i>, this course is about an approach to bringing software engineering up to speed with more traditional engineering disciplines, providing a mathematical foundation for rigorous analysis of realistic computer systems.  As civil engineers apply their mathematical canon to reach high certainty that bridges will not fall down, the software engineer should apply a different canon to argue that programs behave properly.  As other engineering disciplines have their computer-aided-design tools, computer science has <i>proof assistants</i>, IDEs for logical arguments.  We will learn how to apply these tools to certify that programs behave as expected.</p>

      <p><i>More specifically</i>: Introductions to two intertangled subjects: <b><a href="http://coq.inria.fr/">the Coq proof assistant</a>, a tool for machine-checked mathematical theorem proving</b>; and <b>formal logical reasoning about the correctness of programs</b>.  The latter category overlaps significantly with MIT's <a href="http://stellar.mit.edu/S/course/6/fa15/6.820/">6.820</a>, but we will come to appreciate the material at a different level, by focusing on machine-checked proofs, both of the soundness of general reasoning techniques and of the correctness of particular programs.</p>

      <p>We welcome participation by graduate and undergraduate students from MIT and other local universities, as well as other auditors interested in jumping into this material.</p>

      <h2>Major topics covered</h2>

      <p>Here's a tentative syllabus.</p>

      <table class="bs3-table table-striped">
        <tr><th>Foundations</th></tr>
        <tr><td>Inductive types, recursive functions, induction, and rewriting: the heart of formal reasoning, and useful for defining and reasoning about language interpreters</td></tr>
        <tr><td>Inductively defined relations and rule induction, applied to invariant-based verification of state machines</td></tr>
        <tr><td>Model checking and abstraction: finitizing state spaces with clever relations</td></tr>
        <tr><td>Operational semantics: the standard approach to give meanings to programs</td></tr>
        <tr><td>Abstract interpretation and dataflow analysis: computing families of program invariants automatically</td></tr>

        <tr><th>Type Systems</th></tr>
        <tr><td>Lambda-calculus semantics</td></tr>
        <tr><td>Type systems and the syntactic approach to type soundness</td></tr>
        <tr><td>Advanced type-system features: recursive types, polymorphism, subtyping, mutable references</td></tr>

        <tr><th>Program Logics</th></tr>
        <tr><td>Hoare logic: an approach to verifying imperative programs</td></tr>
        <tr><td>Deep embeddings, shallow embeddings, and options in between: choices for how to represent programs formally</td></tr>
        <tr><td>Separation logic: reasoning about aliasing and pointer-based data structures</td></tr>

        <tr><th>Concurrency</th></tr>
        <tr><td>Operational semantics for concurrent programs, illustrated with partial-order reduction for model checking</td></tr>
        <tr><td>Concurrent Separation Logic and rely-guarantee reasoning: verifying shared-memory programs</td></tr>
        <tr><td>Pi-calculus and behavioral refinement: modular reasoning about message-passing functional programs</td></tr>
      </table>

      <h2>The big ideas</h2>

      <p>That's quite a lot of topics, isn't it?  We'll be sticking to techniques for proving <i>safety properties</i> (and we'll clarify what that term means), so there's even a whole other world of foundational ideas for proving other sorts of program properties!  Nonetheless, a key goal of the course is to clarify how all of these techniques can be seen as applying a few <b>big ideas</b> of semantics and verification:</p>

      <table class="bs3-table table-striped">
        <tr><th>Encoding</th> <td>There are an awful lot of different ways to formalize the shape and behavior of programs, and the choice of a method can have big consequences for how easy the proofs are.</td></tr>
        <tr><th>Invariants</th> <td>Almost all program proofs come down to finding invariants of state machines.  That is, we prove that some property holds of all reachable states of a formal system, and we show that the property implies the one we started out trying to prove.</td></tr>
        <tr><th>Abstraction</th> <td>Often we replace one state machine with a simpler one that somehow represents it faithfully enough with respect to the property of interest.</td></tr>
        <tr><th>Modularity</th> <td>We also often break a complex state machine into several simpler ones that can be analyzed independently.</td></tr>
      </table>

      <h2>All homework assignments are mechanized proofs that are checked automatically.</h2>

      <p>As a result, you may or may not want to conclude that the robot uprising is coming sooner than you thought.</p>

      <p>Usually, the Monday class is a more or less traditional <i>lecture</i>, and the Wednesday class is a <i>lab</i>, where students can work together proving suggested theorems on their laptops.  Grades are based entirely on <i>problem sets</i> (graded by the machines), and a new one is released right after each lab, due a week later.</p>

      <h2>Prerequisites</h2>

      <p>Two main categories of prior knowledge are assumed: <i>mathematical foundations of computer science, including rigorous proofs with induction</i>; and <i>intermediate-level programming experience, including familiarity with concepts like higher-order functions, pointers, and multithreading</i>.  MIT's 6.042 and 6.005/6.004 should respectively satisfy those requirements, but many other ways of coming by this core knowledge should also be fine.  We'll start off pretty quickly with functional programming in Coq, as our main vehicle for expressing programs and their specifications.  Many students find it unnecessary to have studied functional programming beforehand, but others appreciate learning a bit about Haskell or OCaml on their own first.  (6.820 also provides lightning-speed introductions to those languages.)</p>

      <h2>Suggested reading</h2>

      <p>The course is intended to be self-contained, and notes and example Coq code will be distributed with all lectures.  We'll also be using a custom Coq library designed to present a relatively small set of primitive commands to be learned.  However, the following popular sources may be helpful supplements.</p>

      <h3>The Coq proof assistant</h3>

      <ul>
        <!--li><a href="https://coq.inria.fr/distrib/current/refman/">Coq reference manual</a></li>
        <li><a href="https://coq.inria.fr/distrib/current/stdlib/">Coq standard-library reference</a></li-->
                                                                                        <li><a href="http://adam.chlipala.net/cpdt/"><i>Certified Programming with Dependent Types</i></a>, the instructor's book introducing Coq at a more advanced level</li>
                                                                                        <li><a href="https://www.labri.fr/perso/casteran/CoqArt/"><i>Interactive Theorem Proving and Program Development (Coq'Art)</i></a>, the first book about Coq</li>
                                                                                        <li><a href="http://www.cis.upenn.edu/~bcpierce/sf/"><i>Software Foundations</i></a>, a popular introduction to Coq that covers ideas similar to the ones in this course, at a slower pace</li>
      </ul>

      <h3>Semantics and program proof</h3>

      <ul>
        <li><a href="https://www.cis.upenn.edu/~bcpierce/tapl/"><i>Types and Programming Languages</i></a></li>
        <li><a href="https://mitpress.mit.edu/books/formal-semantics-programming-languages"><i>The Formal Semantics of Programming Languages: An Introduction</i></a></li>
        <li><a href="http://www.amazon.com/Practical-Foundations-Programming-Languages-Professor/dp/1107029570"><i>Practical Foundations for Programming Languages</i></a></li>
      </ul>

      <h2>This web app...</h2>

      <p>...is built using advanced type-system ideas relevant to the course, and <a href="https://github.com/achlipala/frapapp">the source code is available</a>.  Pull requests welcome!</p>
    </xml>


val main =
    Theme.simple "MIT 6.887, Spring 2016" courseInfo

structure Smu = Sm.MakeUi(struct
                              val steps = {BeforeSemester = {Label = "Before semester",
                                                             WhenEntered = fn _ => return ()},
                                           PollingAboutOfficeHours = {Label = "Polling about office hours",
                                                                      WhenEntered = fn _ => return ()},
                                           SteadyState = {Label = "Steady state",
                                                          WhenEntered = fn _ => return ()},
                                           AssigningFinalGrades = {Label = "Assigning Final Grades",
                                                                   WhenEntered = fn _ => return ()},
                                           SemesterOver = {Label = "Semester over",
                                                           WhenEntered = fn _ => return ()}}
                          end)

structure Private = struct

    val admin =
        requireInstructor;
        Theme.tabbed "MIT 6.887, Spring 2016 Admin"
                     {1 = (Some "Lifecycle",
                           Smu.ui)}

end

val index = return <xml><body>
  <a link={main}>Main</a>
  <a link={Private.admin}>Admin</a>
</body></xml>
