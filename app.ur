open Bootstrap3
structure Theme = Ui.Make(Style)
structure ThisTerm = Spring2016
val calBounds = {FromDay = ThisTerm.regDay,
                 ToDay = ThisTerm.classesDone}

table user : { Kerberos : string, MitId : string, UserName : string, IsInstructor : bool, IsTA : bool, IsStudent : bool, HasDropped : bool,
               Units : string, SubjectNum : string, SectionNum : string, LastName : string, FirstName : string, MiddleInitial : string }
  PRIMARY KEY Kerberos,
  CONSTRAINT UserName UNIQUE UserName

table possibleOfficeHoursTime : { Time : time }
  PRIMARY KEY Time

table lecture : { LectureNum : int, LectureTitle : string, When : time, Description : string }
  PRIMARY KEY LectureNum,
  CONSTRAINT When UNIQUE When

table lab : { LabNum : int, When : time, Description : string }
  PRIMARY KEY LabNum,
  CONSTRAINT When UNIQUE When

table pset : { PsetNum : int, Released : time, Due : time, GradesDue : time, Instructions : string }
  PRIMARY KEY PsetNum

table officeHours : { OhUser : string, When : time }
  PRIMARY KEY When

(* Bootstrap the database with an initial admin user. *)
task initialize = fn () =>
  anyUsers <- oneRowE1 (SELECT COUNT( * ) > 0
                        FROM user);
  if anyUsers then
      return ()
  else
      dml (INSERT INTO user(Kerberos, MitId, UserName, IsInstructor, IsTA, IsStudent, HasDropped, Units, SubjectNum, SectionNum, LastName, FirstName, MiddleInitial)
           VALUES ('adamc', '', 'Adam Chlipala', TRUE, FALSE, FALSE, FALSE, '', '', '', '', '', ''))

structure Auth = MitCert.Make(struct
                                  con kerberos = #Kerberos
                                  con commonName = #UserName
                                  con groups = [IsInstructor, IsTA, IsStudent, HasDropped]
                                  val users = user
                                  val defaults = Some {IsInstructor = False,
                                                       IsTA = False,
                                                       IsStudent = False,
                                                       HasDropped = False,
                                                       MitId = "",
                                                       Units = "",
                                                       SubjectNum = "",
                                                       SectionNum = "",
                                                       LastName = "",
                                                       FirstName = "",
                                                       MiddleInitial = ""}
                                  val allowMasquerade = Some (make [#IsInstructor] ())
                                  val requireSsl = True
                              end)

val whoami' = s <- Auth.whoamiWithMasquerade;
    return (case s of
                None => None
              | Some s => Some {UserName = s})

val gInstructor = make [#IsInstructor] ()
val amInstructor = Auth.inGroup gInstructor
val requireInstructor = Auth.requireGroup gInstructor
val instructorOnly =
    b <- amInstructor;
    return (if b then
                Calendar.Write
            else
                Calendar.Read)

val gStudent = make [#IsStudent] ()
val gTA = make [#IsTA] ()
val gsStudent = (gInstructor, gTA, gStudent)
val whoamiStudent = Auth.getGroupsWithMasquerade gsStudent
val amStudent = Auth.inGroup gStudent

val gsStaff = (gInstructor, gTA)
val whoamiStaff = Auth.getGroups gsStaff
val amStaff = Auth.inGroups gsStaff
val requireStaff = Auth.requireGroups gsStaff
val getStaff = Auth.getGroups gsStaff

val showPset = mkShow (fn {PsetNum = n : int} => "Pset " ^ show n)

structure PsetSub = Submission.Make(struct
                                        val tab = pset
                                        con ukey = #UserName
                                        val user = user
                                        val whoami = Auth.whoamiWithMasquerade
                                        con fs = [Hours = (int, _, _),
                                                  Suggestions = (string, _, _)]
                                        val labels = {Hours = "Hours spent on the pset (round to nearest integer)",
                                                      Suggestions = "Suggestions for improving the pset"}

                                        fun makeFilename k u = "ps" ^ show k.PsetNum ^ "_" ^ u ^ ".v"
                                        fun mayInspect uo =
                                            staff <- amStaff;
                                            if staff then
                                                return True
                                            else
                                                u <- whoamiStudent;
                                                return (uo = Some u)
                                    end)

table psetGrade : { PsetNum : int, PsetStudent : string, Grader : string, When : time, Grade : int, Comment : string }
  PRIMARY KEY (PsetNum, PsetStudent, Grader, When),
  CONSTRAINT PsetNum FOREIGN KEY PsetNum REFERENCES pset(PsetNum) ON UPDATE CASCADE,
  CONSTRAINT Student FOREIGN KEY PsetStudent REFERENCES user(UserName) ON UPDATE CASCADE,
  CONSTRAINT Grader FOREIGN KEY Grader REFERENCES user(UserName) ON UPDATE CASCADE

val psetGradeShow : show {PsetNum : int, PsetStudent : string}
  = mkShow (fn r => "#" ^ show r.PsetNum ^ ", " ^ r.PsetStudent)

structure PsetGrade = Review.Make(struct
                                      con reviewer = #Grader
                                      con reviewed = [PsetNum = _, PsetStudent = _]
                                      val tab = psetGrade
                                      val labels = {Grade = "Grade",
                                                    Comment = "Comment"}
                                      fun summarize r = txt r.Grade
                                      val whoami = u <- whoamiStaff; return (Some u)
                                  end)

val gradeTree = Grades.assignments
                [[PsetNum = _]]
                [#PsetStudent]
                [#When]
                [#Grade]
                [#UserName]
                "Overall"
                pset
                user
                psetGrade

structure GradeTree = struct
    val t = gradeTree
end

structure AllGrades = Grades.AllStudents(GradeTree)
structure StudentGrades = Grades.OneStudent(GradeTree)

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

val usernameShow = mkShow (fn {UserName = s} => s)
val timeShow = mkShow (fn {Time = t : time} => show t)

structure Smu = Sm.MakeUi(struct
                              val steps = {BeforeSemester = {Label = "Before semester",
                                                             WhenEntered = fn _ => return ()},
                                           PollingAboutOfficeHours = {Label = "Polling about office hours",
                                                                      WhenEntered = fn _ => return ()},
                                           SteadyState = {Label = "Steady state",
                                                          WhenEntered = fn _ => return ()},
                                           AssigningFinalGrades = {Label = "Assigning final grades",
                                                                   WhenEntered = fn _ => return ()},
                                           SemesterOver = {Label = "Semester over",
                                                           WhenEntered = fn _ => return ()}}
                          end)

fun getLecture num =
    oneRow1 (SELECT lecture.LectureTitle, lecture.Description, lecture.When
             FROM lecture
             WHERE lecture.LectureNum = {[num]})

val showLecture = mkShow (fn {LectureNum = n : int, LectureTitle = s} => "Lecture " ^ show n ^ ": " ^ s)

structure LectureCal = Calendar.FromTable(struct
                                              con tag = #Lecture
                                              con key = [LectureNum = _, LectureTitle = _]
                                              con times = [When]
                                              val tab = lecture
                                              val title = "Lecture"
                                              val labels = {LectureNum = "Lecture#",
                                                            LectureTitle = "Title",
                                                            Description = "Description",
                                                            When = "When"}
                                              val kinds = {When = ""}
                                              val ws = {Description = Widget.htmlbox} ++ _
                                              val display = Some (fn ctx r =>
                                                                     content <- source <xml/>;
                                                                     lec <- rpc (getLecture r.LectureNum);
                                                                     set content (Ui.simpleModal
                                                                                      <xml>
                                                                                        <h2>Lecture #{[r.LectureNum]}: {[lec.LectureTitle]}</h2>
                                                                                        <h3>{[lec.When]}</h3>
                                                                      
                                                                                        {Widget.html lec.Description}
                                                                                      </xml>
                                                                                      <xml>Close</xml>);
                                                                     return <xml>
                                                                       <dyn signal={signal content}/>
                                                                     </xml>)

                                              val auth = instructorOnly
                                              val showTime = True
                                          end)

fun getLab num =
    oneRow1 (SELECT lab.Description, lab.When
             FROM lab
             WHERE lab.LabNum = {[num]})

val showLab = mkShow (fn {LabNum = n : int} => "Lab " ^ show n)

structure LabCal = Calendar.FromTable(struct
                                          con tag = #Lab
                                          con key = [LabNum = _]
                                          con times = [When]
                                          val tab = lab
                                          val title = "Lab"
                                          val labels = {LabNum = "Lab#",
                                                        Description = "Description",
                                                        When = "When"}
                                          val kinds = {When = ""}
                                          val ws = {Description = Widget.htmlbox} ++ _
                                          val display = Some (fn ctx r =>
                                                                 content <- source <xml/>;
                                                                 lb <- rpc (getLab r.LabNum);
                                                                 set content (Ui.simpleModal
                                                                                  <xml>
                                                                                    <h2>Lab #{[r.LabNum]}</h2>
                                                                                    <h3>{[lb.When]}</h3>
                                                                                    
                                                                                    {Widget.html lb.Description}
                                                                                  </xml>
                                                                                  <xml>Close</xml>);
                                                                 return <xml>
                                                                   <dyn signal={signal content}/>
                                                                 </xml>)

                                          val auth = instructorOnly
                                          val showTime = True
                                      end)

fun getPset num =
    oneRow1 (SELECT pset.Instructions, pset.Released, pset.Due
             FROM pset
             WHERE pset.PsetNum = {[num]})

structure PsetCal = Calendar.FromTable(struct
                                           con tag = #Pset
                                           con key = [PsetNum = _]
                                           con times = [Released, Due]
                                           val tab = pset
                                           val title = "Pset"
                                           val labels = {PsetNum = "Pset#",
                                                         Instructions = "Instructions",
                                                         Released = "Released",
                                                         Due = "Due",
                                                         GradesDue = "Grades due"}
                                           val kinds = {Released = "released", Due = "due"}
                                           val ws = {Instructions = Widget.htmlbox} ++ _
                                           val display = Some (fn ctx r =>
                                                                  content <- source <xml/>;
                                                                  lb <- rpc (getPset r.PsetNum);
                                                                  set content (Ui.simpleModal
                                                                                   <xml>
                                                                                     <h2>Pset #{[r.PsetNum]}</h2>
                                                                                     <h3>Released {[lb.Released]}<br/>
                                                                                     Due {[lb.Due]}</h3>
                                                                                     
                                                                                     <button class="btn btn-primary"
                                                                                              onclick={fn _ =>
                                                                                                          xm <- PsetSub.newUpload r;
                                                                                                          set content xm}>
                                                                                       New Submission
                                                                                     </button>

                                                                                     <hr/>

                                                                                     {Widget.html lb.Instructions}
                                                                                   </xml>
                                                                                   <xml>Close</xml>);
                                                                  return <xml>
                                                                    <dyn signal={signal content}/>
                                                                  </xml>)

                                           val auth = instructorOnly
                                           val showTime = True
                                       end)

val showOh = mkShow (fn {OhUser = s} => s ^ "'s office hours")

structure OhCal = Calendar.FromTable(struct
                                          con tag = #OfficeHours
                                          con key = [OhUser = _]
                                          con times = [When]
                                          val tab = officeHours
                                          val title = "Office Hours"
                                          val labels = {OhUser = "Who",
                                                        When = "When"}
                                          val kinds = {When = ""}
                                          val display = None

                                          val auth = instructorOnly
                                          val showTime = True

                                          val ws = {OhUser = Widget.foreignbox_default
                                                                 (SELECT (user.UserName)
                                                                  FROM user
                                                                  WHERE user.IsInstructor OR user.IsTA)
                                                                 ""} ++ _
                                      end)

structure PublicCal = Calendar.Make(struct
                                        val t = ThisTerm.cal
                                                    |> Calendar.compose OhCal.cal
                                                    |> Calendar.compose PsetCal.cal
                                                    |> Calendar.compose LabCal.cal
                                                    |> Calendar.compose LectureCal.cal
                                    end)

val calUi = Ui.seq (Ui.h4 <xml>
  Lecture and lab are in 34-304.<br/>
  Adam's office hours are in 32-G842.<br/>
  Peng's office hours are in TBD.
</xml>, PublicCal.ui calBounds)

val forumAccess = staff <- amStaff;
    if staff then
        u <- Auth.getUserWithMasquerade;
        return (Discussion.Admin {User = u})
    else
        student <- amStudent;
        if student then
            u <- Auth.getUserWithMasquerade;
            return (Discussion.Post {User = u, MayEdit = True, MayDelete = True, MayMarkClosed = True})
        else
            return Discussion.Read

structure GlobalForum = GlobalDiscussion.Make(struct
                                                  val text = Widget.htmlbox
                                                  val access = forumAccess
                                                  val showOpenVsClosed = True
                                                  val allowPrivate = True
                                                  fun onNewMessage _ = return ()
                                              end)

structure LectureForum = TableDiscussion.Make(struct
                                                  con key1 = #LectureNum
                                                  con keyR = []
                                                  con thread = #Thread
                                                  val parent = lecture

                                                  val text = Widget.htmlbox
                                                  fun access _ = forumAccess
                                                  val showOpenVsClosed = True
                                                  val allowPrivate = True
                                                  fun onNewMessage _ = return ()
                                              end)

structure LabForum = TableDiscussion.Make(struct
                                              con key1 = #LabNum
                                              con keyR = []
                                              con thread = #Thread
                                              val parent = lab

                                              val text = Widget.htmlbox
                                              fun access _ = forumAccess
                                              val showOpenVsClosed = True
                                              val allowPrivate = True
                                              fun onNewMessage _ = return ()
                                          end)

structure PsetForum = TableDiscussion.Make(struct
                                               con key1 = #PsetNum
                                               con keyR = []
                                               con thread = #Thread
                                               val parent = pset

                                               val text = Widget.htmlbox
                                               fun access _ = forumAccess
                                               val showOpenVsClosed = True
                                               val allowPrivate = True
                                               fun onNewMessage _ = return ()
                                           end)

structure LectureTodo = Todo.Happenings(struct
                                            con tag = #Lecture
                                            con key = [LectureNum = _, LectureTitle = _]
                                            con when = #When
                                            val items = lecture
                                            con ukey = #UserName
                                            val users = user
                                            val ucond = (WHERE Users.IsStudent OR Users.IsInstructor OR Users.IsTA)
                                            val title = "Lecture"
                                            fun render r = <xml>{[r]}</xml>
                                        end)

structure LabTodo = Todo.Happenings(struct
                                        con tag = #Lab
                                        con key = [LabNum = _]
                                        con when = #When
                                        val items = lab
                                        con ukey = #UserName
                                        val users = user
                                        val ucond = (WHERE Users.IsStudent OR Users.IsInstructor OR Users.IsTA)
                                        val title = "Lab"
                                        fun render r = <xml>{[r]}</xml>
                                    end)

structure Private = struct

    val adminPerm =
        b <- amInstructor;
        return {Add = b, Delete = b, Modify = b}

    structure EditUser = EditableTable.Make(struct
                                                val tab = user
                                                val labels = {Kerberos = "Kerberos",
                                                              UserName = "Name",
                                                              IsInstructor = "Instructor?",
                                                              IsTA = "TA?",
                                                              IsStudent = "Student?",
                                                              HasDropped = "Dropped?",
                                                              MitId = "MIT ID",
                                                              Units = "Units",
                                                              SubjectNum = "Subject",
                                                              SectionNum = "Section",
                                                              LastName = "Last",
                                                              FirstName = "First",
                                                              MiddleInitial = "MI"}

                                                val permission = adminPerm
                                                fun onAdd _ = return ()
                                                fun onDelete _ = return ()
                                                fun onModify _ = return ()
                                            end)

    structure EditPossOh = EditableTable.Make(struct
                                                  val tab = possibleOfficeHoursTime
                                                  val labels = {Time = "Time"}

                                                  val permission = adminPerm
                                                  fun onAdd _ = return ()
                                                  fun onDelete _ = return ()
                                                  fun onModify _ = return ()
                                              end)

    structure OhPoll = ClosedBallot.Make(struct
                                             con voterKey1 = #UserName
                                             con voterKeyR = []
                                             val voter = user

                                             con choiceBallot = []
                                             con choiceKey1 = #Time
                                             con choiceKeyR = []
                                             val choice = possibleOfficeHoursTime

                                             val amVoter = whoami'
                                             val maxVotesPerVoter = Some 1
                                             val keyFilter = (WHERE TRUE)
                                         end)

    structure StudentTodo = Todo.Make(struct
                                          val t = LectureTodo.todo
                                                      |> Todo.compose LabTodo.todo
                                      end)

    fun student masqAs =
        (case masqAs of
             "" => Auth.unmasquerade
           | _ => Auth.masqueradeAs masqAs);

        u <- whoamiStudent;
        key <- return {UserName = u};
        st <- Sm.current;

        lec <- oneOrNoRows1 (SELECT lecture.LectureNum, lecture.LectureTitle, lecture.When, lecture.Description
                             FROM lecture
                             WHERE lecture.When < CURRENT_TIMESTAMP
                             ORDER BY lecture.When DESC
                             LIMIT 1);

        lecr <- return (Option.get {LectureNum = 0,
                                    LectureTitle = "",
                                    When = minTime,
                                    Description = ""} lec);

        lb <- oneOrNoRows1 (SELECT lab.LabNum, lab.When, lab.Description
                            FROM lab
                            WHERE lab.When < CURRENT_TIMESTAMP
                            ORDER BY lab.When DESC
                            LIMIT 1);

        lbr <- return (Option.get {LabNum = 0,
                                   When = minTime,
                                   Description = ""} lb);

        ps <- oneOrNoRows1 (SELECT pset.PsetNum, pset.Released, pset.Due, pset.Instructions
                            FROM pset
                            WHERE pset.Released < CURRENT_TIMESTAMP AND CURRENT_TIMESTAMP < pset.Due
                            ORDER BY pset.Due DESC
                            LIMIT 1);

        psr <- return (Option.get {PsetNum = 0,
                                   Released = minTime,
                                   Due = minTime,
                                   Instructions = ""} ps);

        Theme.tabbed "MIT 6.887, Spring 2016, student page"
        ((Ui.when (st = make [#PollingAboutOfficeHours] ()) "Poll on Favorite Office-Hours Times",
          OhPoll.ui {Ballot = (), Voter = key}),
         (Some "Todo",
          StudentTodo.OneUser.ui u),
         (Some "Calendar",
          calUi),

         (case ps of
              None => None
            | Some _ => Some "Current Pset",
          Ui.seq (Ui.constM (fn ctx => <xml>
            <h2>Pset {[psr.PsetNum]}</h2>
            <h3>Released: {[psr.Released]}<br/>
            Due: {[psr.Due]}</h3>
            {Widget.html psr.Instructions}<br/>

            {Ui.modalButton ctx (CLASS "btn btn-primary") <xml>New Submission</xml>
                            (PsetSub.newUpload {PsetNum = psr.PsetNum})}
           
            <hr/>
          </xml>),
                  PsetSub.AllFiles.ui {Key = {PsetNum = psr.PsetNum}, User = u},
                  Ui.const <xml>
                    <hr/>
                    <h2>Forum</h2>
                  </xml>,
                  PsetForum.ui {PsetNum = psr.PsetNum})),

         (case lec of
              None => None
            | Some _ => Some "Last Lecture",
          Ui.seq (Ui.const <xml>
            <h2>Lecture {[lecr.LectureNum]}: {[lecr.LectureTitle]}</h2>
            <h3>{[lecr.When]}</h3>
            {Widget.html lecr.Description}
            
            <hr/>
            
            <h2>Forum</h2>
          </xml>,
                  LectureForum.ui {LectureNum = lecr.LectureNum})),

         (case lb of
              None => None
            | Some _ => Some "Last Lab",
          Ui.seq (Ui.const <xml>
            <h2>Lab {[lbr.LabNum]}</h2>
            <h3>{[lbr.When]}</h3>
            {Widget.html lbr.Description}
            
            <hr/>
            
            <h2>Forum</h2>
          </xml>,
                  LabForum.ui {LabNum = lbr.LabNum})),

         (Some "Global Forum",
          GlobalForum.ui),
         (Ui.when (st > make [#BeforeSemester] ()) "Grades",
          Ui.seq (Ui.h4 <xml>The range shows your possible final averages, based on grades earned on the remaining assignments.</xml>,
                  StudentGrades.ui u)),
         (Some "Course Info",
          courseInfo))

    structure PsetCal = Calendar.FromTable(struct
                                               con tag = #Pset
                                               con key = [PsetNum = _]
                                               con times = [Released, Due, GradesDue]
                                               val tab = pset
                                               val title = "Pset"
                                               val labels = {PsetNum = "Pset#",
                                                             Instructions = "Instructions",
                                                             Released = "Released",
                                                             Due = "Due",
                                                             GradesDue = "Grades due"}
                                               val kinds = {Released = "released", Due = "due", GradesDue = "grades due"}
                                               val ws = {Instructions = Widget.htmlbox} ++ _
                                               val display = Some (fn ctx r =>
                                                                      content <- source <xml/>;
                                                                      lb <- rpc (getPset r.PsetNum);
                                                                      set content (Ui.simpleModal
                                                                                       <xml>
                                                                                         <h2>Pset #{[r.PsetNum]}</h2>
                                                                                         <h3>Released {[lb.Released]}<br/>
                                                                                         Due {[lb.Due]}</h3>
                                                                                         
                                                                                         {Widget.html lb.Instructions}
                                                                                       </xml>
                                                                                       <xml>Close</xml>);
                                                                      return <xml>
                                                                        <dyn signal={signal content}/>
                                                                      </xml>)

                                               val auth = instructorOnly
                                               val showTime = True
                                           end)

    structure AdminCal = Calendar.Make(struct
                                           val t = ThisTerm.cal
                                                       |> Calendar.compose OhCal.cal
                                                       |> Calendar.compose PsetCal.cal
                                                       |> Calendar.compose LabCal.cal
                                                       |> Calendar.compose LectureCal.cal
                                       end)

    structure WS = WebSIS.Make(struct
                                   val user = user

                                   val defaults = {IsInstructor = False,
                                                   IsTA = False}
                                   val amAuthorized = amInstructor
                                   val expectedSubjectNumber = "6.887"
                               end)

    fun psetGrades n u =
        requireStaff;
        Theme.simple ("Grading Pset #" ^ show n ^ ", " ^ u)
                     (Ui.seq
                          (PsetSub.AllFiles.ui {Key = {PsetNum = n}, User = u},
                           PsetGrade.One.ui {PsetNum = n, PsetStudent = u}))

    val admin =
        requireInstructor;
        tm <- now;
        st <- Sm.current;

        masq <- queryX1 (SELECT user.UserName
                         FROM user
                         WHERE user.IsStudent
                         ORDER BY user.UserName)
                        (fn r => <xml>
                          <tr><td><a link={student r.UserName}>{[r.UserName]}</a></td></tr>
                        </xml>);

        Theme.tabbed "MIT 6.887, Spring 2016 Admin"
                     ((Some "Lifecycle",
                       Smu.ui),
                      (Some "Calendar",
                       AdminCal.ui calBounds),
                      (Some "Import",
                       WS.ui),
                      (Some "Users",
                       EditUser.ui),
                      (Ui.when (st < make [#SteadyState] ()) "Possible OH times",
                       Ui.seq (Ui.h4 <xml>Enter times like "{[tm]}".  Only the time part will be shown to students.</xml>,
                               EditPossOh.ui)),
                      (Some "Masquerade",
                       Ui.const <xml>
                         <table class="bs3-table table-striped">
                           {masq}
                         </table>
                       </xml>))

    structure Students = SimpleQuery1.Make(struct
                                               val query = (SELECT user.Kerberos, user.UserName
                                                            FROM user
                                                            WHERE user.IsStudent
                                                            ORDER BY user.UserName DESC)

                                               val labels = {Kerberos = "Kerberos",
                                                             UserName = "Name"}
                                           end)

    structure StaffTodo = Todo.Make(struct
                                        val t = LectureTodo.todo
                                                    |> Todo.compose LabTodo.todo
                                    end)

    val staff =
        u <- getStaff;
        key <- return {UserName = u};
        st <- Sm.current;

        lec <- oneOrNoRows1 (SELECT lecture.LectureNum, lecture.LectureTitle, lecture.When, lecture.Description
                             FROM lecture
                             WHERE lecture.When < CURRENT_TIMESTAMP
                             ORDER BY lecture.When DESC
                             LIMIT 1);

        lecr <- return (Option.get {LectureNum = 0,
                                    LectureTitle = "",
                                    When = minTime,
                                    Description = ""} lec);

        lb <- oneOrNoRows1 (SELECT lab.LabNum, lab.When, lab.Description
                            FROM lab
                            WHERE lab.When < CURRENT_TIMESTAMP
                            ORDER BY lab.When DESC
                            LIMIT 1);

        lbr <- return (Option.get {LabNum = 0,
                                   When = minTime,
                                   Description = ""} lb);

        ps <- oneOrNoRows1 (SELECT pset.PsetNum, pset.Released, pset.Due, pset.Instructions
                            FROM pset
                            WHERE pset.Released < CURRENT_TIMESTAMP AND CURRENT_TIMESTAMP < pset.Due
                            ORDER BY pset.Due DESC
                            LIMIT 1);

        psr <- return (Option.get {PsetNum = 0,
                                   Released = minTime,
                                   Due = minTime,
                                   Instructions = ""} ps);

        Theme.tabbed "MIT 6.887, Spring 2016 Staff"
                     ((Ui.when (st = make [#PollingAboutOfficeHours] ()) "Poll on Favorite Office-Hours Times",
                       OhPoll.ui {Ballot = (), Voter = key}),
                      (Some "Todo",
                       StaffTodo.OneUser.ui u),
                      (Some "Calendar",
                       AdminCal.ui calBounds),
                      (case ps of   
                           None => None
                         | Some _ => Some "Current Pset",
                       Ui.seq (Ui.const <xml>
                         <h2>Pset {[psr.PsetNum]}</h2>
                         <h3>Released: {[psr.Released]}<br/>
                         Due: {[psr.Due]}</h3>
                         {Widget.html psr.Instructions}

                         <hr/>

                         <h2>Forum</h2>
                       </xml>,
                       PsetForum.ui {PsetNum = psr.PsetNum})),

                      (case lec of
                           None => None
                         | Some _ => Some "Last Lecture",
                       Ui.seq (Ui.const <xml>
                         <h2>Lecture {[lecr.LectureNum]}: {[lecr.LectureTitle]}</h2>
                         <h3>{[lecr.When]}</h3>
                         {Widget.html lecr.Description}

                         <hr/>

                         <h2>Forum</h2>
                       </xml>,
                               LectureForum.ui {LectureNum = lecr.LectureNum})),

                      (case lb of
                           None => None
                         | Some _ => Some "Last Lab",
                       Ui.seq (Ui.const <xml>
                         <h2>Lab {[lbr.LabNum]}</h2>
                         <h3>{[lbr.When]}</h3>
                         {Widget.html lbr.Description}

                         <hr/>

                         <h2>Forum</h2>
                       </xml>,
                               LabForum.ui {LabNum = lbr.LabNum})),

                      (Some "Global Forum",
                       GlobalForum.ui),
                      (Some "Students",
                       Students.ui),
                      (Ui.when (st > make [#PollingAboutOfficeHours] ()) "Grades",
                       AllGrades.ui))

end

val main =
    st <- Sm.current;

    Theme.tabbed "MIT 6.887, Spring 2016"
                 ((Some "Course Info",
                   Ui.seq (Ui.const (if st = make [#BeforeSemester] () then
                                         <xml></xml>
                                     else
                                         <xml><p>
                                           <a class="btn btn-primary btn-lg" link={Private.student ""}>Go to student portal</a>
                                           (requires an <a href="https://ist.mit.edu/certificates">MIT client certificate</a>)
                                         </p></xml>),
                           courseInfo)),
                  (Some "Calendar",
                   calUi))

val index = return <xml><body>
  <a link={main}>Main</a>
  <a link={Private.admin}>Admin</a>
  <a link={Private.staff}>Staff</a>
  <a link={Private.student ""}>Student</a>
  <a link={Private.psetGrades 0 ""}>Grade</a>
</body></xml>
